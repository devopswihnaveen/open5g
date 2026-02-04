#!/bin/bash

set -e

# Configuration
NAMESPACE="${NAMESPACE:-open5gs}"
BACKUP_DIR="${BACKUP_DIR:-/tmp/open5gs-backups}"
S3_BUCKET="${S3_BUCKET:-open5gs-prod-backups}"
AWS_REGION="${AWS_REGION:-us-east-1}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup MongoDB
backup_mongodb() {
    print_info "Backing up MongoDB..."
    
    local mongodb_pod=$(kubectl get pods -n "$NAMESPACE" -l app=mongodb -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$mongodb_pod" ]; then
        print_error "MongoDB pod not found"
        return 1
    fi
    
    local backup_file="$BACKUP_DIR/mongodb-backup-$TIMESTAMP.archive"
    
    kubectl exec -n "$NAMESPACE" "$mongodb_pod" -- mongodump \
        --archive=/tmp/backup.archive \
        --gzip \
        --db=open5gs
    
    kubectl cp "$NAMESPACE/$mongodb_pod:/tmp/backup.archive" "$backup_file"
    
    print_info "MongoDB backup completed: $backup_file"
}

# Backup ConfigMaps
backup_configmaps() {
    print_info "Backing up ConfigMaps..."
    
    local configmaps_dir="$BACKUP_DIR/configmaps-$TIMESTAMP"
    mkdir -p "$configmaps_dir"
    
    kubectl get configmaps -n "$NAMESPACE" -o yaml > "$configmaps_dir/configmaps.yaml"
    
    print_info "ConfigMaps backup completed: $configmaps_dir"
}

# Backup Secrets
backup_secrets() {
    print_info "Backing up Secrets..."
    
    local secrets_dir="$BACKUP_DIR/secrets-$TIMESTAMP"
    mkdir -p "$secrets_dir"
    
    kubectl get secrets -n "$NAMESPACE" -o yaml > "$secrets_dir/secrets.yaml"
    
    print_info "Secrets backup completed: $secrets_dir"
}

# Backup PersistentVolumeClaims
backup_pvcs() {
    print_info "Backing up PersistentVolumeClaims..."
    
    local pvcs_dir="$BACKUP_DIR/pvcs-$TIMESTAMP"
    mkdir -p "$pvcs_dir"
    
    kubectl get pvc -n "$NAMESPACE" -o yaml > "$pvcs_dir/pvcs.yaml"
    
    print_info "PVCs backup completed: $pvcs_dir"
}

# Create tarball
create_tarball() {
    print_info "Creating tarball..."
    
    local tarball="$BACKUP_DIR/open5gs-backup-$TIMESTAMP.tar.gz"
    tar -czf "$tarball" -C "$BACKUP_DIR" \
        "mongodb-backup-$TIMESTAMP.archive" \
        "configmaps-$TIMESTAMP" \
        "secrets-$TIMESTAMP" \
        "pvcs-$TIMESTAMP"
    
    # Remove individual backup directories
    rm -rf "$BACKUP_DIR/mongodb-backup-$TIMESTAMP.archive" \
           "$BACKUP_DIR/configmaps-$TIMESTAMP" \
           "$BACKUP_DIR/secrets-$TIMESTAMP" \
           "$BACKUP_DIR/pvcs-$TIMESTAMP"
    
    print_info "Tarball created: $tarball"
    echo "$tarball"
}

# Upload to S3
upload_to_s3() {
    local tarball=$1
    print_info "Uploading backup to S3..."
    
    aws s3 cp "$tarball" "s3://$S3_BUCKET/backups/" --region "$AWS_REGION"
    
    print_info "Backup uploaded to S3: s3://$S3_BUCKET/backups/$(basename $tarball)"
}

# Cleanup old backups
cleanup_old_backups() {
    print_info "Cleaning up old backups..."
    
    # Cleanup local backups
    find "$BACKUP_DIR" -name "open5gs-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    # Cleanup S3 backups
    aws s3 ls "s3://$S3_BUCKET/backups/" --region "$AWS_REGION" | \
        awk '{print $4}' | \
        while read -r file; do
            file_date=$(echo "$file" | grep -oP '\d{8}')
            if [ -n "$file_date" ]; then
                file_age=$(( ($(date +%s) - $(date -d "$file_date" +%s)) / 86400 ))
                if [ $file_age -gt $RETENTION_DAYS ]; then
                    aws s3 rm "s3://$S3_BUCKET/backups/$file" --region "$AWS_REGION"
                    print_info "Deleted old backup: $file"
                fi
            fi
        done
    
    print_info "Cleanup completed"
}

# Restore from backup
restore_backup() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will restore from backup: $backup_file"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Restore cancelled"
        exit 0
    fi
    
    print_info "Extracting backup..."
    local extract_dir="$BACKUP_DIR/restore-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$extract_dir"
    tar -xzf "$backup_file" -C "$extract_dir"
    
    # Restore MongoDB
    print_info "Restoring MongoDB..."
    local mongodb_pod=$(kubectl get pods -n "$NAMESPACE" -l app=mongodb -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$mongodb_pod" ]; then
        print_error "MongoDB pod not found"
        exit 1
    fi
    
    local mongodb_backup=$(find "$extract_dir" -name "mongodb-backup-*.archive" | head -n 1)
    kubectl cp "$mongodb_backup" "$NAMESPACE/$mongodb_pod:/tmp/restore.archive"
    kubectl exec -n "$NAMESPACE" "$mongodb_pod" -- mongorestore --archive=/tmp/restore.archive --gzip --drop
    
    # Restore ConfigMaps
    print_info "Restoring ConfigMaps..."
    local configmaps_dir=$(find "$extract_dir" -type d -name "configmaps-*" | head -n 1)
    kubectl apply -f "$configmaps_dir/configmaps.yaml"
    
    # Restore Secrets
    print_info "Restoring Secrets..."
    local secrets_dir=$(find "$extract_dir" -type d -name "secrets-*" | head -n 1)
    kubectl apply -f "$secrets_dir/secrets.yaml"
    
    print_info "Restore completed successfully"
    
    # Cleanup extract directory
    rm -rf "$extract_dir"
}

# Main execution
case "${1:-backup}" in
    backup)
        backup_mongodb
        backup_configmaps
        backup_secrets
        backup_pvcs
        tarball=$(create_tarball)
        upload_to_s3 "$tarball"
        cleanup_old_backups
        print_info "Backup process completed successfully"
        ;;
    restore)
        if [ -z "$2" ]; then
            print_error "Please provide backup file path"
            echo "Usage: $0 restore <backup-file>"
            exit 1
        fi
        restore_backup "$2"
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Usage: $0 [backup|restore <file>|cleanup]"
        exit 1
        ;;
esac
