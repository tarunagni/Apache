#!/bin/bash

configure_path=/home/$USER/reverse-proxy

# URL for Apache HTTPD setup
# Function to extract the latest version from the Apache HTTP Server download page
get_latest_version() {
    # Fetching the download page and extracting version numbers
    versions=$(curl -s https://downloads.apache.org/httpd/ | grep -o 'httpd-[0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d'-' -f2- | sort -V)

    # Getting the latest version
    latest_version=$(echo "$versions" | tail -n1)

    echo "$latest_version"
}

latest_version=$(get_latest_version)

if [ -n "$latest_version" ]; then
    echo "Latest version found: $latest_version"
    APACHE_URL="https://downloads.apache.org/httpd/httpd-$latest_version.tar.gz"
    echo "Download URL: $APACHE_URL"
    # You can perform further actions here, like downloading the file using curl or wget
else
    echo "Failed to retrieve the latest version."
fi


# Step 1: Install dependencies
dependencies=("APR libraries" "GCC" "PCRE development libraries")
failed_dependencies=()
for dependency in "${dependencies[@]}"; do
    sudo yum install -y apr apr-* gcc pcre-devel
    if [ $? -ne 0 ]; then
        failed_dependencies+=("$dependency")
    fi
done

if [ ${#failed_dependencies[@]} -gt 0 ]; then
    echo "Error: Failed to install the following dependencies:"
    for failed_dependency in "${failed_dependencies[@]}"; do
        echo " - $failed_dependency"
    done
    exit 1
else
    echo "Dependencies installed successfully."
fi

# Check if the file exists
if wget --spider "$APACHE_URL" 2>/dev/null; then
    # Check if the file is already downloaded
    if [ -e "httpd-$latest_version.tar.gz" ]; then
        echo "Apache HTTPD setup file already downloaded. Skipping download."
    else
        # Download Apache HTTPD setup
        wget "$APACHE_URL"
    fi
else
    echo "Error: URL does not exist. Please check the URL or your internet connection."
    exit 1
fi

# Check if the file has been downloaded before proceeding
if [ ! -e "httpd-$latest_version.tar.gz" ]; then
    echo "Error: Apache HTTPD setup file not found. Please check the download process."
    exit 1
fi

# Step 2: Extract tar file
if tar -xvzf httpd-$latest_version.tar.gz; then
    echo "Tar extraction successful."
else
    echo "Error: Tar extraction failed. Please check the archive or permissions."
    exit 1
fi


# Step 3: Install Apache HTTPD
cd httpd-$latest_version
./configure --prefix=$configure_path
if [ $? -eq 0 ]; then
    echo "Configuration successful."
else
    echo "Error: Configuration failed."
    exit 1
fi

sudo make clean
if [ $? -eq 0 ]; then
    echo "Cleanup successful."
else
    echo "Error: Cleanup failed."
    exit 1
fi

sudo make
if [ $? -eq 0 ]; then
    echo "Make successful."
else
    echo "Error: Make failed."
    exit 1
fi

sudo make install
if [ $? -eq 0 ]; then
    echo "Installation successful."
else
    echo "Error: Installation failed."
    exit 1
fi

echo "Apache HTTPD installation completed."
