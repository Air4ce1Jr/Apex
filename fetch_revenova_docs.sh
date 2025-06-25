#!/bin/bash
set -e

# List of Revenova TMS documentation URLs
urls=(
"https://documents.revenova.com/docs/revenova-tms-release-notes"
"https://documents.revenova.com/docs/revenova-tms-installation-guide"
"https://documents.revenova.com/docs/data-dictionary"
"https://documents.revenova.com/docs/revenova-tms-web-services-guide"
"https://documents.revenova.com/docs/integrations"
"http://documents.revenova.com/docs/field-set-summary"
"https://documents.revenova.com/docs/lightning-web-components-lwcs"
"https://documents.revenova.com/docs/fleet-management-2"
"https://documents.revenova.com/docs/accounting-seed-1"
"https://documents.revenova.com/docs/payiq"
"https://documents.revenova.com/docs/revenova-tms-analytics-user-guide"
)

# Base directory for docs
base_dir="docs/Revenova Docs"
mkdir -p "$base_dir"

for url in "${urls[@]}"; do
    # Extract last path segment
    segment=$(echo "$url" | awk -F"/" '{print $NF}')
    dest_dir="$base_dir/$segment"
    mkdir -p "$dest_dir"

    headers=$(mktemp)
    tmpfile=$(mktemp)

    # Fetch URL with headers
    curl -L -s -D "$headers" "$url" -o "$tmpfile"

    # Determine content type
    ctype=$(grep -i "^content-type" "$headers" | tail -n1 | tr -d '\r')
    if echo "$ctype" | grep -qi "pdf"; then
        out="$dest_dir/index.pdf"
    else
        out="$dest_dir/index.html"
    fi

    mv "$tmpfile" "$out"
    rm "$headers"
    echo "Saved $url -> $out"
    sleep 1
done

# Create EXTERNAL_LINKS.md
cat <<'EOL' > "$base_dir/EXTERNAL_LINKS.md"
- **Salesforce Developer Documentation**  
  https://help.salesforce.com/s/products/platform?language=en_US

- **Estes Express API Developer Portal**  
  https://developer.estes-express.com/

- **ABF Freight (ArcBest) Shipping APIs**  
  https://arcb.com/technology/shippers/API

- **Ward Transport & Logistics API**  
  https://wardtlctools.com/wardtrucking/apirequest/create

- **A Duie Pyle Web Services**  
  https://aduiepyle.com/resources/it-support/

- **Saia Motor Freight Line Developer Portal**  
  https://saiaprodapi.developer.azure-api.net/

- **Southeastern Freight Lines Web Connect API**  
  https://www.sefl.com/seflWebsite/technology/webConnect.jsp
EOL

echo "Finished fetching docs and writing external links." 
