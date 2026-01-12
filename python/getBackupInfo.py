from lxml import etree
import sys

backupName = sys.argv[1]
backupTreeFile = "backupList.xml"
if len(sys.argv) == 3:
    backupTreeFile = sys.argv[2]

backupTree = etree.parse(backupTreeFile)
backupRoot = backupTree.getroot()

if backupName == "backupList":
    xpath = """backup[@name]""" 
    backupElements = backupRoot.xpath(xpath)
    for backup in backupElements:
        print(backup.attrib['name'])
    
else:    
 
    xpath = """backup[@name='%s']""" % backupName
   
    backupElement = backupRoot.xpath(xpath)[0]

    for attr in backupElement.attrib:
        print("BACKUP_%s=\"%s\"" %(attr.upper(),backupElement.attrib[attr]))

    for command in backupElement.getchildren():
        if command.tag is etree.Comment:
            continue

        cmd = command.tag.upper()

        value = ""
        if command.text:
            value = command.text
        print("""%s_%s=\"%s\"""" % ("BACKUP", cmd, value))
