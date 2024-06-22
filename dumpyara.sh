    #!/bin/bash
    #set -e
    # Replace links accordingly

    OEMZIP=www.link.com
    DT=https://github.com/narikootam-dev/device_xiaomi_sweet
    VT=https://github.com/narikootam-dev/vendor_xiaomi_sweet
    DEVICENAME=xiaomi/sweet # enter device name accordingly


    #Intialising 
    echo -e "$green << Initialising script >> \n $white"
    echo -e "$green << cloning dumpyara >> \n $white"
    git clone https://github.com/AndroidDumps/dumpyara dumpyara
    cd dumpyara
    echo -e "$green << setting up >> \n $white"
    bash setup.sh
    echo -e "$green << setup is completed >> \n $white"

    # dump your oem zip
    echo -e "$green << dumping oem zip >> \n $white"
    ./dumpyara.sh $OEMZIP       
    echo -e "$green << dumping success>> \n $white"

    # clone extract tools
    echo -e "$green << cloning essential extracting tool >> \n $white"
    git clone https://github.com/LineageOS/android_tools_extract-utils -b lineage-21.0 android/tools/extract-utils
    git clone https://github.com/LineageOS/android_prebuilts_extract-tools -b lineage-21.0 android/prebuilts/extract-tools

    #clone device tree
    echo -e "$green << cloning device tree >> \n $white"
    git clone $DT android/device/$DEVICENAME 
    echo -e "$green << cloning success >> \n $white"

    #clone vendor tree
    echo -e "$green << cloning vendor tree >> \n $white"
    git clone $VT android/vendor/$DEVICENAME
    echo -e "$green << cloning success >> \n $white"

    echo -e "$green << dumpyara setup finished! Happy dumping :) >> \n $white"
