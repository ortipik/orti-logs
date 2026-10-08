#!/bin/bash
#<!-- Copyright (c) 2026 ortipik - Licence MIT (voir fichier LICENSE) -->
#-----------------------------------------------------------------------
# ce script a été élaboré par Ortipik pour OMEGA-server.
# https://kraynux.snake-mackarel.ts.net
#-----------------------------------------------------------------------

# ============================================
# GESTION DES LOGS SERVER
# Script de maintenance et d'analyse des logs
# ============================================

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'
# ======================================================================
# partie a configurer, indiquer vos chemins de logs voulu 
# -----------------------------------------
LOG_FILE="/var/log/lighttpd/access.log"
BACKUP_DIR="/var/log/lighttpd/backups"
# -----------------------------------------
========================================================================

# Créer le dossier de backup si inexistant
sudo mkdir -p "$BACKUP_DIR"

show_menu() {
    clear
    echo -e "${BLUE}🔷====================================================${NC}"
    echo -e "${BLUE}🔷    GESTION DES LOGS : WEB-SERVER-ACCES             ${NC}"
    echo -e "${BLUE}🔷====================================================${NC}"
    echo ""
    
    # Afficher les stats
    if [ -f "$LOG_FILE" ]; then
        SIZE=$(du -h "$LOG_FILE" | cut -f1)
        LINES=$(wc -l < "$LOG_FILE")
        echo -e "${GREEN}📊 Taille: $SIZE | Lignes: $LINES${NC}"
    else
        echo -e "${RED}❌ Fichier log non trouvé${NC}"
    fi
    
    # Compter les backups
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.log 2>/dev/null | wc -l)
    echo -e "${GREEN}📦 Backups disponibles: $BACKUP_COUNT${NC}"
    echo ""
    
    echo -e "${GREEN}1)${NC} Traiter une IP spécifique"
    echo -e "${GREEN}2)${NC} Vider complètement les logs"
    echo -e "${GREEN}3)${NC} Garder les 1000 dernières lignes"
    echo -e "${GREEN}4)${NC} Supprimer les logs de plus de 7 jours"
    echo -e "${GREEN}5)${NC} Afficher les IPs les plus fréquentes (top 20)"
    echo -e "${MAGENTA}6)${NC} 💾 Sauvegarder le fichier de log"
    echo -e "${MAGENTA}7)${NC} 📂 Lister les backups disponibles"
    echo -e "${MAGENTA}8)${NC} 🔄 Restaurer un backup"
    echo -e "${RED}0)${NC} Quitter"
    echo ""
}

# Fonction de sauvegarde
backup_log() {
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local backup_file="$BACKUP_DIR/access.log-$timestamp"
    
    echo -e "${YELLOW}💾 Sauvegarde du fichier de log...${NC}"
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}❌ Aucun fichier log à sauvegarder${NC}"
        return 1
    fi
    
    # Copier le fichier
    sudo cp "$LOG_FILE" "$backup_file"
    
    # Compresser
    sudo gzip "$backup_file"
    
    echo -e "${GREEN}✅ Backup créé: $backup_file.gz${NC}"
    
    # Afficher la taille
    SIZE=$(du -h "$backup_file.gz" | cut -f1)
    echo -e "${GREEN}📊 Taille du backup: $SIZE${NC}"
    
    # Nettoyer les backups de plus de 30 jours
    echo -e "${YELLOW}🧹 Nettoyage des backups de plus de 30 jours...${NC}"
    sudo find "$BACKUP_DIR" -name "*.gz" -mtime +30 -delete
}

# Fonction pour lister les backups
list_backups() {
    echo ""
    echo -e "${BLUE}📂 Backups disponibles:${NC}"
    echo -e "${BLUE}-----------------------------------${NC}"
    
    if [ -z "$(ls -1 "$BACKUP_DIR"/*.gz 2>/dev/null)" ]; then
        echo -e "${YELLOW}Aucun backup trouvé${NC}"
        return 1
    fi
    
    local i=1
    for backup in $(ls -1t "$BACKUP_DIR"/*.gz 2>/dev/null); do
        local name=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" | cut -d'.' -f1)
        echo -e "  ${GREEN}$i)${NC} $name ${YELLOW}($size)${NC} - $date"
        ((i++))
    done
    
    echo ""
}

# Fonction pour restaurer un backup
restore_backup() {
    list_backups
    
    if [ $? -eq 1 ]; then
        return
    fi
    
    echo ""
    read -p "🔢 Numéro du backup à restaurer: " backup_num
    
    # Récupérer le nom du fichier correspondant
    local backup_file=$(ls -1t "$BACKUP_DIR"/*.gz 2>/dev/null | sed -n "${backup_num}p")
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}❌ Backup invalide${NC}"
        return
    fi
    
    echo -e "${YELLOW}⚠️  Restaurer $backup_file ? (o/N)${NC}"
    read confirm
    if [[ $confirm =~ ^[OoYy]$ ]]; then
        # Sauvegarder le fichier actuel avant restauration
        backup_log
        
        # Décompresser et restaurer
        sudo gunzip -c "$backup_file" | sudo tee "$LOG_FILE" > /dev/null
        
        echo -e "${GREEN}✅ Backup restauré${NC}"
        echo -e "${YELLOW}📊 Nouvelles stats: $(wc -l < "$LOG_FILE") lignes${NC}"
    else
        echo -e "${GREEN}Opération annulée${NC}"
    fi
}

# Fonction pour traiter une IP spécifique
handle_ip() {
    echo -e "${YELLOW}📊 IPs les plus fréquentes dans les logs:${NC}"
    echo -e "${BLUE}-----------------------------------${NC}"
    awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -20 | while read count ip; do
        echo -e "  ${GREEN}$count${NC} fois - ${RED}$ip${NC}"
    done
    
    echo ""
    read -p "🔍 Entrez l'IP à traiter (ou 'q' pour annuler): " TARGET_IP
    
    if [[ "$TARGET_IP" == "q" ]]; then
        return
    fi
    
    if ! [[ $TARGET_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}❌ Format IP invalide: $TARGET_IP${NC}"
        return
    fi
    
    COUNT=$(grep -c "$TARGET_IP" "$LOG_FILE")
    echo ""
    echo -e "${BLUE}📊 IP $TARGET_IP apparaît $COUNT fois dans les logs${NC}"
    echo ""
    
    if [ $COUNT -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Cette IP n'apparaît pas dans les logs${NC}"
        return
    fi
    
    echo -e "${YELLOW}Que voulez-vous faire avec cette IP ?${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Supprimer toutes les lignes de cette IP"
    echo -e "${GREEN}2)${NC} Masquer l'IP (remplacer par ***BLOCKED***)"
    echo -e "${GREEN}3)${NC} Afficher les lignes de cette IP"
    echo -e "${GREEN}4)${NC} Compter uniquement les occurrences"
    echo -e "${RED}0)${NC} Annuler"
    echo ""
    read -p "? Votre choix (0-4): " CHOICE
    
    case $CHOICE in
        1)
            # Sauvegarder avant suppression
            echo -e "${YELLOW}💾 Sauvegarde automatique avant modification...${NC}"
            backup_log
            
            echo -e "${YELLOW}🧹 Suppression des lignes contenant $TARGET_IP...${NC}"
            sudo sed -i "/$TARGET_IP/d" "$LOG_FILE"
            
            NEW_COUNT=$(grep -c "$TARGET_IP" "$LOG_FILE" 2>/dev/null || echo "0")
            if [ "$NEW_COUNT" -eq 0 ]; then
                echo -e "${GREEN}✅ Toutes les lignes de $TARGET_IP ont été supprimées${NC}"
            else
                echo -e "${RED}❌ Problème: $NEW_COUNT lignes restantes${NC}"
            fi
            ;;
        2)
            # Sauvegarder avant modification
            echo -e "${YELLOW}💾 Sauvegarde automatique avant modification...${NC}"
            backup_log
            
            echo -e "${YELLOW}🔍 Masquage de l'IP $TARGET_IP...${NC}"
            sudo sed -i "s/$TARGET_IP/***BLOCKED***/g" "$LOG_FILE"
            echo -e "${GREEN}✅ IP masquée : $TARGET_IP → ***BLOCKED***${NC}"
            ;;
        3)
            echo ""
            echo -e "${BLUE}📋 Dernières lignes contenant $TARGET_IP:${NC}"
            echo -e "${BLUE}-----------------------------------${NC}"
            grep "$TARGET_IP" "$LOG_FILE" | tail -20
            echo ""
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        4)
            echo ""
            echo -e "${BLUE}📊 Statistiques pour $TARGET_IP:${NC}"
            echo -e "${BLUE}-----------------------------------${NC}"
            echo -e "  Occurrences totales: ${GREEN}$COUNT${NC}"
            LAST=$(grep "$TARGET_IP" "$LOG_FILE" | tail -1 | cut -d'[' -f2 | cut -d']' -f1)
            echo -e "  Dernière apparition: ${YELLOW}$LAST${NC}"
            echo ""
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        0)
            echo -e "${GREEN}Opération annulée${NC}"
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            ;;
    esac
}

# Menu principal
while true; do
    show_menu
    read -p "? Votre choix: " main_choice
    
    case $main_choice in
        1)
            handle_ip
            ;;
        2)
            echo -e "${YELLOW}⚠️  Vider complètement les logs ? (o/N)${NC}"
            read confirm
            if [[ $confirm =~ ^[OoYy]$ ]]; then
                backup_log
                echo -e "${YELLOW}⏹️  Arrêt de lighttpd...${NC}"
                sudo systemctl stop lighttpd
                echo -e "${YELLOW}🧹 Suppression du fichier...${NC}"
                sudo rm -f "$LOG_FILE"
                echo -e "${YELLOW}▶️  Redémarrage de lighttpd...${NC}"
                sudo systemctl start lighttpd
                echo -e "${GREEN}✅ Logs vidés${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}💾 Sauvegarde avant réduction...${NC}"
            backup_log
            echo -e "${YELLOW}📋 Garder les 1000 dernières lignes...${NC}"
            sudo tail -n 1000 "$LOG_FILE" > /tmp/lighttpd.log
            sudo mv /tmp/lighttpd.log "$LOG_FILE"
            echo -e "${GREEN}✅ Fichier réduit à 1000 lignes${NC}"
            ;;
        4)
            echo -e "${YELLOW}🧹 Suppression des logs de plus de 7 jours...${NC}"
            sudo find /var/log/lighttpd/ -name "*.log.*" -mtime +7 -delete
            echo -e "${GREEN}✅ Anciens logs supprimés${NC}"
            ;;
        5)
            echo ""
            echo -e "${BLUE}📊 Top 20 IPs les plus fréquentes:${NC}"
            echo -e "${BLUE}-----------------------------------${NC}"
            awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -20
            echo ""
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        6)
            backup_log
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        7)
            list_backups
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        8)
            restore_backup
            read -p "Appuyez sur Entrée pour continuer..."
            ;;
        0)
            echo -e "${GREEN}👋 Au revoir !${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Choix invalide${NC}"
            ;;
    esac
done
