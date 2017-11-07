package ballerina.pmml;

function getDataFieldElements (xml dataDictionary) (xml) {
    xml dataFields = dataDictionary.children().elements().strip();
    return dataFields;
}

function getDataFieldElement (xml dataDictionary, int elementNumber) (xml) {
    xml dataFieldElements = getDataFieldElements(dataDictionary);
    return dataFieldElements[elementNumber];
}

function getNumberOfDataFields (xml dataDictionary) (int) {
    // TODO the `.elements()` part should be in getDataFieldElements() function.
    xml dataFields = getDataFieldElements(dataDictionary);
    return lengthof dataFields;
}

function getDataFieldElementsWithoutTarget (xml dataDictionary, string targetName) (xml) {
    // TODO complete
    int i = 0;
    xml dataFields = getDataFieldElements(dataDictionary).elements();
    xml dataFieldsWithoutTarget;
    while (i < lengthof dataFields) {
        xml dataField = dataFields[i];
        if (dataField@["name"] != targetName) {
            if (i == 0) {
                dataFieldsWithoutTarget = dataField;
            } else {
                dataFieldsWithoutTarget = dataFieldsWithoutTarget + dataField;
            }
        }
        i = i + 1;
    }
    return dataFieldsWithoutTarget;
}
