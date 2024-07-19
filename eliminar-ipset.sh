#!/bin/bash

# Obtener el nombre del host
HOSTNAME=$(hostname)

# Obtener el listado de VMIDs
VMIDS=$(qm list | awk 'NR>1 {print $1}')

# Iterar sobre cada VMID
for VMID in $VMIDS; do
    echo "Procesando VMID: $VMID"

    # Obtener el listado de IPSet para el VMID actual en formato JSON
    IPSETS_JSON=$(pvesh get /nodes/$HOSTNAME/qemu/$VMID/firewall/ipset --output-format json)

    # Iterar sobre cada IPSet
    echo $IPSETS_JSON | jq -c '.[]' | while IFS=$"\n" read -r IPSET; do
        NAME=$(echo $IPSET | jq -r '.name')

        if [[ -z "$NAME" ]]; then
            echo "  No se encontró IPSet para VMID $VMID"
            continue
        fi
        echo "  Procesando IPSet: $NAME"

        # Obtener el listado de CIDRs para el IPSet actual en formato JSON
        CIDRS_JSON=$(pvesh get /nodes/$HOSTNAME/qemu/$VMID/firewall/ipset/$NAME --output-format json)

        # Iterar sobre cada CIDR y eliminarlo
        echo $CIDRS_JSON | jq -c '.[]' | while IFS=$"\n" read -r CIDR_ENTRY; do
            CIDR=$(echo $CIDR_ENTRY | jq -r '.cidr')

            if [[ -z "$CIDR" ]]; then
                echo "    No se encontró CIDR en IPSet $NAME para VMID $VMID"
                continue
            fi
            echo "    Eliminando CIDR: $CIDR"
            pvesh delete /nodes/$HOSTNAME/qemu/$VMID/firewall/ipset/$NAME/$CIDR
        done

        # Eliminar el IPSet una vez que todos los CIDRs han sido eliminados
        echo "  Eliminando IPSet: $NAME"
        pvesh delete /nodes/$HOSTNAME/qemu/$VMID/firewall/ipset/$NAME
    done
done

echo "Proceso completado."
