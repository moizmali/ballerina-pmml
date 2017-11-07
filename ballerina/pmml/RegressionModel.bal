package ballerina.pmml;

import ballerina.log;

public function executeRegressionModel (xml pmml, xml data) (float) {
    float result;
    // TODO get rid of the global variables.
    // TODO change the input or json data as a xml data (then convert it to json).
    // Check if the argument is a valid PMML element.
    if (!isValid(pmml)) {
        throw invalidPMMLElementError();
    }

    xml modelElement = getModelElement(pmml);
    string functionName = modelElement@["functionName"];
    if (functionName == "regression") {
        result = executeRegressionFunction(pmml, data);
    }
    return result;
}

function executeRegressionFunction (xml pmml, xml data) (float) {
    // TODO rearrange all of this.
    // Get the data dictionary element.
    xml dataDictionaryElement = getDataDictionaryElement(pmml);

    // Get the model element.
    xml modelElement = getModelElement(pmml);

    // Get the number of data fields in the PMML.
    int numberOfFields = getNumberOfDataFields(pmml);

    // Obtain the <RegressionTable> element from the PMML.
    xml regressionTableElement = modelElement.selectChildren("RegressionTable");

    // Obtain the intercept value of the linear regression.
    var intercept, _ = <float>regressionTableElement@["intercept"];

    // Get the <MiningSchema> element.
    xml miningSchema = modelElement.selectChildren("MiningSchema");

    // Get all the <MiningField> elements from the mining schema.
    xml miningFields = miningSchema.children().elements();

    // Identify the target field from the mining schema.
    string targetFieldName;
    int i = 0;
    while (i < lengthof miningFields) {
        xml miningField = miningFields[i];
        if (miningField@["usageType"] == "target") {
            targetFieldName = miningField@["name"];
            break;
        }
        i = i + 1;
    }

    // Obtain all the predictor elements from the DataFields and add it to the JSON.
    json dataFieldsJSON = [];
    i = 0;
    xml dataFieldElementsWithoutTarget = getDataFieldElementsWithoutTarget(dataDictionaryElement, targetFieldName).elements();
    while (i < lengthof dataFieldElementsWithoutTarget) {
        xml field = dataFieldElementsWithoutTarget[i];
        if (field@["name"] != targetFieldName) {
            json fieldJSON = {};
            fieldJSON.name = field@["name"];
            fieldJSON.optype = field@["optype"];
            fieldJSON.dataType = field@["dataType"];
            if (field@["optype"] == "categorical") {
                fieldJSON.value = {};
            }
            dataFieldsJSON[i] = fieldJSON;
        }
        i = i + 1;
    }

    // Obtain all predictor elements and add it to a JSON array.
    xml regressionTableChildren = regressionTableElement.children().elements();
    json predictorElements = [];
    i = 0;
    while (i < lengthof regressionTableChildren) {
        xml predictorElement = regressionTableChildren[i];
        json predictor = {};
        string predictorName = predictorElement.getElementName();
        if (predictorName.contains("NumericPredictor")) {

            predictor.name = predictorElement@["name"];
            predictor.optype = "continuous";

            var exponent, _ = <int>predictorElement@["exponent"];
            predictor.exponent = exponent;

            var coefficient, _ = <float>predictorElement@["coefficient"];
            predictor.coefficient = coefficient;

        } else if (predictorName.contains("CategoricalPredictor")) {

            predictor.name = predictorElement@["name"];
            predictor.optype = "categorical";
            predictor.value = predictorElement@["value"];

            var coefficient, _ = <float>predictorElement@["coefficient"];
            predictor.coefficient = coefficient;
        }
        predictorElements[i] = predictor;
        i = i + 1;
    }

    // Add a loop inside a loop to merge the predictorElements and the dataFields together.
    i = 0;
    while (i < lengthof dataFieldsJSON) {
        int count = 0;
        while (count < (lengthof predictorElements)) {
            if (dataFieldsJSON[i].name.toString() == predictorElements[count].name.toString()) {
                string optypeStr = dataFieldsJSON[i].optype.toString();
                if (optypeStr == "continuous") {
                    dataFieldsJSON[i].exponent = predictorElements[count].exponent;
                    dataFieldsJSON[i].coefficient = predictorElements[count].coefficient;
                } else if (optypeStr == "categorical") {
                    string value = predictorElements[count].value.toString();
                    dataFieldsJSON[i].value[value] = predictorElements[count].coefficient;
                }
            }
            count = count + 1;
        }
        i = i + 1;
    }

    // Create empty JSON element to store the PMML data.
    json regressionModelJSON = {};
    // Add the intercept.
    regressionModelJSON.intercept = intercept;
    // Add empty predictor array
    regressionModelJSON.predictors = dataFieldsJSON;
    // Add the predictorElements to the regressionModelJSON JSON.
    //i = 0;
    //while (i < lengthof predictorElements) {
    //    regressionModelJSON.predictors[i] = predictorElements[i];
    //    i = i + 1;
    //}

    // Get the information of the target value and add it to the regressionModelJSON JSON. // TODO can merge with other code.
    xml dataFields = getDataFieldElements(dataDictionaryElement);
    xml dataField;
    string dataFieldName;
    i = 0;
    while (i < lengthof dataFields) {
        dataField = dataFields[i];
        dataFieldName = dataField@["name"];
        if (dataFieldName == targetFieldName) {
            json targetJSON = {
                                  name:dataField@["name"],
                                  optype:dataField@["optype"],
                                  dataType:dataField@["dataType"]
                              };
            regressionModelJSON.target = targetJSON;
            break;
        }
        i = i + 1;
    }

    // Convert the xml `data` variable to JSON to calculate the output.
    xmlOptions options = {};
    json dataJSON = data.children().elements().toJSON(options);

    // TODO Create the linear regression equation using the found values and return the output.
    float output = calculateOutput(regressionModelJSON, dataJSON);
    return output;
}

function calculateOutput (json model, json data) (float) {
    var output, _ = <float>model.intercept.toString();
    int numberOfPredictors = lengthof model.predictors;
    int i = 0;
    while (i < numberOfPredictors) {
        string name = model.predictors[i].name.toString();
        string opType = model.predictors[i].optype.toString();
        string valueStr = data[name].toString();
        var coefficient = 0.0;
        var value = 0.0;
        if (opType == "continuous") {
            coefficient, _ = <float>model.predictors[i].coefficient.toString();
            value, _ = <float>valueStr;
        } else if (opType == "categorical") {
            coefficient, _ = <float>model.predictors[i].value[valueStr].toString();
            value = 1;
        }
        output = output + (coefficient * value);

        i = i + 1;
    }

    // TODO there may be other variations to this.
    string targetFieldDataType = model.target.dataType.toString();
    if (targetFieldDataType == "integer") {
        return <int>output;
    } else {
        return output;
    }
}