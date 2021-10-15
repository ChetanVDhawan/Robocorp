*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Tables
Library    RPA.Browser
Library    RPA.HTTP
Library    RPA.Dialogs
Library    RPA.PDF
Library    RPA.Desktop
Library    RPA.Archive
Library    RPA.Robocloud.Secrets
Library    OperatingSystem

*** Variables ***
${pdf_folder}=        ${CURDIR}${/}pdf_files${/}
${img_folder}=        ${CURDIR}${/}image_files${/}
${output_folder}=     ${CURDIR}${/}output${/}
${zip_file}=          ${CURDIR}${/}output${/}pdf_archive.zip

*** Keywords ***
Input from Dialog
    Add heading     Information
    Add text input    name_id    label=Enter your Name
    ${result}=    Run dialog
    Log To Console     Hello ${result.name_id}
    
Open Website and Login
    Log To Console    Open Browser and Launch Website Started
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Page Contains Element   css:.btn-dark    timeout=60
    Click Button    css:.btn-dark
    Log To Console    Open Browser and Launch Website Ended

*** Keywords ***
Initial BOT Selection
    [Arguments]    ${sales_rep}
            Log To Console    Enter data in Webpage Started
            Log To Console    ${sales_rep}[Head]
            Log To Console    ${sales_rep}[Body]
            Log To Console    ${sales_rep}[Legs]
            Log To Console    ${sales_rep}[Address]


            Wait Until Element Is Visible   //*[@id="head"]
            Wait Until Element Is Enabled   //*[@id="head"]
            Select From List By Value       //*[@id="head"]         ${sales_rep}[Head]

            Wait Until Element Is Enabled   body
            Select Radio Button             body          ${sales_rep}[Body]

            Wait Until Element Is Enabled   xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
            Input Text                      xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input           ${sales_rep}[Legs]
            
            Wait Until Element Is Enabled   //*[@id="address"]
            Input Text                       //*[@id="address"]       ${sales_rep}[Address]
            Click Element    css:#preview
            Sleep    5Sec
            
            
            Click Button    css:#preview
            Click Element If Visible    css:#preview
            FOR     ${i}    IN RANGE    9999999
                    Log To Console    until badge is not found
                    ${css_badgeSeen}=    Is Element Visible   css:.badge
                    IF    ${css_badgeSeen}
                        Log To Console    Badge seen
                    ELSE
                        Log To Console    Badge not seen
                        Click Element   css:#order
                    END
                    Exit For Loop If    ${css_badgeSeen}
            END
            Log To Console    End of the Loop
            
            
            Log To Console    Enter data in Webpage Ended

            Take Screenshot and embed in file


Take Screenshot and embed in file
    Log To Console    Take Screenshot and Embed File Started
    ${orderid}=                     Get Text            css:.badge
    Log To Console    order id is : ${orderid}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${orderid}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    # ${receiptHTML}=    Get Element Attribute    css:#receipt    outerHTML
    # Html To Pdf    ${receiptHTML}   abc.pdf
    Set Local Variable    ${fully_qualified_img}    ${img_folder}${/}${orderid}.PNG
    Screenshot    css:#robot-preview-image    ${fully_qualified_img}

    Open Pdf    ${fully_qualified_pdf_filename}
    @{myfiles}=       Create List  ${fully_qualified_img}:x=0,y=0

    Add Files To Pdf      ${myfiles}        ${fully_qualified_pdf_filename}    append:True
    Close Pdf    ${fully_qualified_pdf_filename}

    Click Button    css:#order-another
    Click Element If Visible    css:#order-another
    Wait Until Page Contains Element   css:.btn-dark    timeout=60
    Click Button    css:.btn-dark
    Log To Console    Take Screenshot and Embed File Ended


Download CSV File From Website
    Log To Console    Download Csv Started
    Download    https://robotsparebinindustries.com/orders.csv  overwrite=True
    Log To Console    Download Csv Completed
    
Fill The Form Using The Data From The Excel File
    Log To Console    Fill Data in Excel Started
    
    ${sales_reps}=    Read Table From Csv   orders.csv   header=True
    FOR     ${sales_rep}     IN     @{sales_reps}
        Initial BOT Selection    ${sales_rep}
    END
    Log To Console    Fill Data in Excel Started

Create a Zip File
    Archive Folder With ZIP     ${pdf_folder}  ${zip_file}   recursive=True  include=*.pdf

Close the Browser
    Close Browser

Get Data From Our Vault
    Log To Console          Getting Secret from our Vault Started
    ${secret}=              Get Secret      main
    Log                     ${secret}[DeveloperName] is developer!      console=yes
    Log To Console          Getting Secret from our Vault Ended

Clean Folder
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Create Directory    ${output_folder}
    Empty Directory     ${img_folder}
    Empty Directory     ${pdf_folder}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Input from Dialog
    Clean Folder
    Get Data From Our Vault
    Open Website and Login
    Download CSV File From Website
    Fill The Form Using The Data From The Excel File
    [Teardown]    Close the Browser
    Create a ZIP file
    Log to Console    Program end successfully
