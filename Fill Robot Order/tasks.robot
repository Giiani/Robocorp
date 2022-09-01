*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.PDF
Library    RPA.Tables
Library    RPA.Salesforce
Library    RPA.RobotLogListener
Library    RPA.Dialogs
Library    RPA.Archive
Library    RPA.FileSystem
Library    RPA.Robocloud.Secrets

*** Variables ***
${url}    https://robotsparebinindustries.com/#/robot-order
${url_csv}    https://robotsparebinindustries.com/orders.csv
${image_folder}    ${CURDIR}${/}imagesFiles
${pdf_folder}     ${CURDIR}${/}pdfFiles
${out_folder}    ${CURDIR}${/}outputFiles
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create folders

    #Get Author from Vault
    ${username}=    Get The User Name
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
       Close the annoying modal
       Fill the form    ${row}
       Wait Until Keyword Succeeds    10x    2s    Preview the robot
       Wait Until Keyword Succeeds    10x    2s    Submit the order
       ${order_id}  ${screenshot}=    Take a screenshot of the robot
       ${pdf}=    Store the receipt as a PDF file    ORDER_Number=${order_id}     
       Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
       Go to order another robot
    END

    Create a ZIP file of the receipts  
    [Teardown]    Close the browser
    Display Success Dialogs    USER_NAME=${username}

*** Keywords ***
Create folders
    Log To Console    Creating folder for Files

    Create Directory    ${image_folder}
    Create Directory    ${pdf_folder}
    Create Directory    ${out_folder}

    Empty Directory    ${image_folder}
    Empty Directory    ${pdf_folder}
    Empty Directory    ${out_folder}

Open the robot order website
    Open Available Browser   url=${url} 

Get orders
    Download    url=${url_csv}
    ${table}    Read table from CSV    orders.csv
    [Return]    ${table}

Fill the form
    [Arguments]    ${row}

    Set Local Variable    ${choose_head}    //*[@id="head"] 
    Set Local Variable    ${choose_body}    body
    Set Local Variable    ${number_legs}    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input 
    Set Local Variable    ${shipping_addres}   //*[@id="address"]

    Wait Until Element Is Visible    ${choose_head}
    Wait Until Element Is Enabled    ${choose_head}
    Select From List By Value    ${choose_head}    ${row}[Head]

    Wait Until Element Is Enabled    ${choose_body}
    Select Radio Button    ${choose_body}    ${row}[Body]

    Wait Until Element Is Enabled    ${number_legs}
    Input Text    ${number_legs}    ${row}[Legs]

    Wait Until Element Is Enabled    ${shipping_addres}
    Input Text    ${shipping_addres}    ${row}[Address]

Preview the robot
    Set Local Variable    ${button_preview}    //*[@id="preview"]
    Set Local Variable    ${preview_image}    //*[@id="robot-preview-image"]
    Click Button    ${button_preview}
    Wait Until Element Is Visible    ${preview_image}

Submit the order
    Set Local Variable    ${button_order}    //*[@id="order"]
    Set Local Variable    ${order_receipt}    //*[@id="receipt"]
    
    Mute Run On Failure    Page Should Contain Element

    Click Button    ${button_order}
    Page Should Contain Element    ${order_receipt}

Store the receipt as a PDF file
    [Arguments]    ${ORDER_Number}

    Wait Until Element Is Visible    //*[@id="receipt"]
    Log To Console    Printing ${ORDER_Number}
    ${order_receipt}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    
    Set Local Variable    ${pdf_filename}   ${pdf_folder}${/}${ORDER_Number}.pdf

    Html To Pdf    content=${order_receipt}    output_path=${pdf_filename}

    [Return]    ${pdf_filename}

Take a screenshot of the robot
    Set Local Variable    ${preview_image}    //*[@id="robot-preview-image"]
    Set Local Variable    ${orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]

    Wait Until Element Is Visible    ${preview_image}
    Wait Until Element Is Visible    ${orderid}

    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]

    Set Local Variable    ${img_file}    ${image_folder}${/}${orderid}.png

    Sleep    1sec
    Log To Console    Capturing Screenshot to ${img_file}
    Capture Element Screenshot    ${preview_image}    ${img_file}

    [Return]    ${orderid}    ${img_file}


Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${image}    ${pdf}

    Log To Console    Printing Embedding image ${image} in pdf file ${pdf}
    

    @{myfiles}=    Create List    ${image}:x=0,y=0

    Add Files To Pdf    ${myfiles}    ${pdf}    ${True}

    

Go to order another robot
    Set Local Variable    ${order_another_bot}    //*[@id="order-another"]
    Wait Until Element Is Visible    ${order_another_bot}
    Click Button    ${order_another_bot}

Close the annoying modal
    Click Button    OK

Create a ZIP file of the receipts
    Archive Folder With Zip    ${pdf_folder}    ${out_folder}${/}output.zip    recursive=True    include=*.pdf

Close the browser
    Close Browser

Get Author from Vault
    Log To Console    Getting Secret Author
    ${secret}    Get Secret    Autor
    Log    ${secret} make this robot    console=yes

Get The User Name
    Add heading    I am RoboCorp Order Filler
    Add text input    myname    label=What's your name?    placeholder=Name:
    ${result}=    Run dialog
    [Return]    ${result}

Display Success Dialogs
    [Arguments]    ${username}
    Add icon    Success
    Add heading    Your orders have been processed
    Add text    Dear ${username} - all the orders have been processed.
    Run dialog    title=Success
Minimal task
    Log    Done.


