#!/bin/bash

echo "=== Test du POC Cantaloupe + MinIO ==="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des services
check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=0
    
    log_info "Vérification de $service_name..."
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            log_info "$service_name est disponible ✓"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    log_error "$service_name n'est pas disponible après ${max_attempts} tentatives"
    return 1
}

# Fonction pour uploader une image de test
upload_test_image() {
    log_info "Upload d'une image de test..."
    
    # Création d'une image de test simple si elle n'existe pas
    if [ ! -f "test-image.jpg" ]; then
        log_info "Création d'une image de test..."
        # Utilisation d'ImageMagick si disponible
        if command -v convert &> /dev/null; then
            convert -size 800x600 xc:lightblue -pointsize 72 -fill darkblue -gravity center -annotate +0+0 "Test IIIF" test-image.jpg
        else
            log_warning "ImageMagick non disponible, téléchargement d'une image de test..."
            curl -o test-image.jpg "https://via.placeholder.com/800x600/lightblue/darkblue.jpg?text=Test+IIIF"
        fi
    fi
    
    # Upload vers MinIO
    docker exec minio-poc mc cp /tmp/test-image.jpg myminio/images/test-image.jpg 2>/dev/null || \
    docker cp test-image.jpg minio-poc:/tmp/test-image.jpg && \
    docker exec minio-poc mc alias set myminio http://localhost:9000 minioadmin minioadmin123 && \
    docker exec minio-poc mc cp /tmp/test-image.jpg myminio/images/test-image.jpg
    
    if [ $? -eq 0 ]; then
        log_info "Image uploadée avec succès ✓"
        return 0
    else
        log_error "Échec de l'upload de l'image"
        return 1
    fi
}

# Tests IIIF
test_iiif_endpoints() {
    log_info "Test des endpoints IIIF..."
    
    # Test du manifest info.json
    log_info "Test de l'endpoint info.json..."
    info_response=$(curl -s "http://localhost:8182/iiif/2/test-image.jpg/info.json")
    if echo "$info_response" | grep -q '"@context"'; then
        log_info "Endpoint info.json OK ✓"
    else
        log_error "Endpoint info.json KO"
        echo "Réponse: $info_response"
    fi
    
    # Test d'une image dérivée
    log_info "Test de génération d'image dérivée..."
    if curl -s "http://localhost:8182/iiif/2/test-image.jpg/full/200,/0/default.jpg" -o test-derivative.jpg; then
        if [ -f "test-derivative.jpg" ] && [ -s "test-derivative.jpg" ]; then
            log_info "Génération d'image dérivée OK ✓"
            rm -f test-derivative.jpg
        else
            log_error "Génération d'image dérivée KO - fichier vide"
        fi
    else
        log_error "Génération d'image dérivée KO - erreur réseau"
    fi
}

# Script principal
main() {
    log_info "Démarrage des tests du POC..."
    
    # Vérification des services
    if ! check_service "MinIO" "http://localhost:9000/minio/health/live"; then
        exit 1
    fi
    
    if ! check_service "Cantaloupe" "http://localhost:8182/"; then
        exit 1
    fi
    
    # Upload et tests
    if upload_test_image; then
        sleep 5  # Attendre que Cantaloupe détecte l'image
        test_iiif_endpoints
    fi
    
    log_info "=== URLs utiles ==="
    echo "MinIO Console: http://localhost:9001 (minioadmin/minioadmin123)"
    echo "Cantaloupe: http://localhost:8182"
    echo "IIIF Info: http://localhost:8182/iiif/2/test-image.jpg/info.json"
    echo "Image test: http://localhost:8182/iiif/2/test-image.jpg/full/400,/0/default.jpg"
    
    log_info "POC testé avec succès ! ✓"
}

# Exécution
main "$@"