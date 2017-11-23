package ballerina.pmml;

import ballerina.log;
import ballerina.math;

function executeRegressionModel (xml pmml, xml data) (float) {
    // TODO add logistic regression.
    float result;
    // Check if the argument is a valid PMML element.
    if (!isValid(pmml)) {
        throw invalidPMMLElementError();
    }

    // TODO look for duplicate child elements.
    // Check whether the <data> element entered is valid.
    boolean isEmpty = data.isEmpty();
    boolean isSingleton = data.isSingleton();
    boolean isElement = (data.getItemType() == "element");
    if (!(!isEmpty && isSingleton && isElement)) {
        throw generateError("invalid data element entered");
    }

    xml modelElement = getModelElement(pmml);
    string functionName = modelElement@["functionName"];
    if (functionName == "regression") {
        if ((lengthof getRegressionTableElements(getModelElement(pmml)) == 1)) {
            result = executeLinearRegression(pmml, data);
        } else if ((lengthof getRegressionTableElements(getModelElement(pmml)) == 2)) {
            executeLogisticRegression(pmml, data); // TODO this should return a result.
        } else {
            throw generateError("more than 2 regression table elements found, use classification instead");
        }
    } else if (functionName == "classification") {
        executeClassification(pmml, data);// TODO this should return a result.
    } else {
        throw generateError("no valid 'functionName' attribute found");
    }
    return result;
}

function executeLinearRegression (xml pmml, xml data) (float) {
    int i = 0;
    int c = 0;

    // Get the <DataDictionary> element as a JSON.
    json dataDictionaryJSON = {};
    dataDictionaryJSON.dataFields = [];
    xml dataFieldsXML = getDataFieldElements(getDataDictionaryElement(pmml));
    i = 0;
    while (i < lengthof dataFieldsXML) {
        json dataField = {};
        dataField.name = dataFieldsXML[i]@["name"];
        dataField.optype = dataFieldsXML[i]@["optype"];
        dataField.dataType = dataFieldsXML[i]@["dataType"];

        if (dataFieldsXML[i]@["optype"] == "categorical") {
            xml values = dataFieldsXML.selectChildren("Value");
            dataField.values = [];
            c = 0;
            while (c < lengthof values) {
                dataField.values[c] = values[c]@["value"];
                c = c + 1;
            }
        }

        dataDictionaryJSON.dataFields[i] = dataField;
        i = i + 1;
    }
    log:printInfo("Data Dictionary: " + dataDictionaryJSON.toString());

    // Get the <MiningSchema> element as a JSON.
    json miningSchemaJSON = {};
    miningSchemaJSON.miningFields = [];
    xml miningSchemaXML = getMiningFieldElements(getMiningSchemaElement(pmml));
    i = 0;
    while (i < lengthof miningSchemaXML) {
        json miningField = {};
        miningField.name = miningSchemaXML[i]@["name"];
        if (!(miningSchemaXML[i]@["usageType"] == "")) {
            miningField.usageType = miningSchemaXML[i]@["usageType"];
        } else {
            miningField.usageType = "active";
        }
        miningSchemaJSON.miningFields[i] = miningField;
        i = i + 1;
    }
    log:printInfo("Mining Schema: " + miningSchemaJSON.toString());

    // Get the <RegressionTable> element as a JSON.
    json regressionTableJSON = {};
    xml regressionTableElement = getRegressionTableElements(getModelElement(pmml));
    regressionTableJSON.intercept = regressionTableElement@["intercept"];
    xml regressionTableXML = regressionTableElement.children().elements();
    regressionTableJSON.predictors = [];
    i = 0;
    while (i < lengthof regressionTableXML) {
        json predictor = {};
        if (regressionTableXML[i].getElementName().contains("NumericPredictor")) {
            predictor.predictorType = "numericPredictor";
            predictor.name = regressionTableXML[i]@["name"];
            predictor.exponent = regressionTableXML[i]@["exponent"];
            predictor.coefficient = regressionTableXML[i]@["coefficient"];
        } else if (regressionTableXML[i].getElementName().contains("CategoricalPredictor")) {
            predictor.predictorType = "categoricalPredictor";
            predictor.name = regressionTableXML[i]@["name"];
            predictor.value = regressionTableXML[i]@["value"];
            predictor.coefficient = regressionTableXML[i]@["coefficient"];
        }
        regressionTableJSON.predictors[i] = predictor;
        i = i + 1;
    }
    log:printInfo("Regression Table: " + regressionTableJSON.toString());

    // TODO check the data and see whether the input is valid.
    // Convert the data XML entered by the user to JSON.
    xmlOptions options = {};
    json dataJSON = data.children().strip().toJSON(options);
    log:printInfo("Data Entered: " + dataJSON.toString());
    float output = calculateLinearRegressionOutput(dataDictionaryJSON, miningSchemaJSON, regressionTableJSON, dataJSON);

    return output;
}

function calculateLinearRegressionOutput (json dataDictionary, json miningSchema, json regressionTable, json data) (float) {
    var output, _ = <float>regressionTable.intercept.toString();
    int i = 0;
    while (i < lengthof regressionTable.predictors) {
        if (regressionTable.predictors[i].predictorType.toString() == "numericPredictor") {
            string name = regressionTable.predictors[i].name.toString();
            var value, _ = <float>data[name].toString();
            var exponent, _ = <int>regressionTable.predictors[i].exponent.toString();
            var coefficient, _ = <float>regressionTable.predictors[i].coefficient.toString();
            output = output + (coefficient * math:pow(value, exponent));
        } else if (regressionTable.predictors[i].predictorType.toString() == "categoricalPredictor") {
            string name = regressionTable.predictors[i].name.toString();
            string regressionTableValue = regressionTable.predictors[i].value.toString();
            string dataValue = data[name].toString();
            int value = 0;
            if (dataValue == regressionTableValue) {
                value = 1;
            }
            var coefficient, _ = <float>regressionTable.predictors[i].coefficient.toString();
            output = output + (coefficient * value);
        }

        i = i + 1;
    }


    string targetFieldName = "";
    i = 0;
    while (i < lengthof miningSchema.miningFields) {
        if (miningSchema.miningFields[i].usageType.toString() == "target") {
            targetFieldName = miningSchema.miningFields[i].name.toString();
            break;
        }
        i = i + 1;
    }

    if (targetFieldName == "") {
        throw generateError("unable to find the target field");
    }

    i = 0;
    while (i < lengthof dataDictionary.dataFields) {
        if (dataDictionary.dataFields[i].name.toString() == targetFieldName) {
            if (dataDictionary.dataFields[i].dataType.toString() == "integer") {
                output = <int>output;
            }
        }

        i = i + 1;
    }
    log:printInfo("Output: " + output);
    return output;
}

function executeLogisticRegression (xml pmml, xml data) {
    // TODO complete.
}

function calculateLogisticRegressionOutput () {
    // TODO complete.
}

function executeClassification (xml pmml, xml data) {
    // TODO complete.
    // Get the normalization method.
    string normalizationMethod = getModelElement(pmml)@["normalizationMethod"];

    // Get the values from the regression table
    xml regressionTables = getRegressionTableElements(getModelElement(pmml));
    float[] values = [];
    float sumOfValues = 0;
    int i = 0;
    while (i < lengthof regressionTables) {
        xml regressionTable = regressionTables[i];
        values[i] = getYValue(regressionTable, data);
        sumOfValues = sumOfValues + values[i];
        i = i + 1;
    }
    print("Values: ");
    println(values);
    print("Sum Of Values: ");
    println(sumOfValues);

    // TODO find the result category.
    float[] probabilities = [];
    i = 0;
    while (i < lengthof values) {
        if (normalizationMethod == "softmax") {
            probabilities[i] = math:exp(values[i]) / (math:exp(sumOfValues));
        } else if (normalizationMethod == "simplemax") {
            probabilities[i] = values[i] / sumOfValues;
        }
        i = i + 1;
    }
    print("Probabilities: ");
    println(probabilities);

    // Find the maximum probability.
    float max = 1E-100000;
    i = 0;
    while (i < lengthof probabilities) {
        if (probabilities[i] > max) {
            max = probabilities[i];
        }
        i = i + 1;
    }
    println("Max: "+ max);

    // Get the target category.
    string targetCategory;
    i = 0;
    while (i < lengthof probabilities) {
        if (probabilities[i] == max) {
            xml regressionTable = regressionTables[i];
            targetCategory = regressionTable@["targetCategory"];
        }
        i = i + 1;
    }
    println("Target Category: " + targetCategory);
}

function getRegressionTableElements (xml modelElement) (xml) {
    xml regressionTableElement = modelElement.selectChildren("RegressionTable");
    if (regressionTableElement.isEmpty()) {
        throw generateError("no regression table element found");
    }
    return regressionTableElement;
}

function getYValue (xml regressionTable, xml data) (float) {
    var intercept, _ = <float>regressionTable@["intercept"];
    if (regressionTable.strip().children().isEmpty()) {
        return intercept;
    }

    float output = intercept;
    int i = 0;
    xml predictors = regressionTable.strip().children().elements();
    while (i < lengthof predictors) {
        xml predictor = predictors[i];
        string elementName = predictor.getElementName();
        if (elementName.contains("NumericPredictor")) {
            string name = predictor@["name"];
            var exponent, _ = <int>predictor@["exponent"];
            if (exponent == 0) {
                exponent = 1;
            }
            var coefficient, _ = <float>predictor@["coefficient"];
            var independent = 0.0;
            if (hasChildElement(data, name)) {
                independent, _ = <float>data.selectChildren(name).getTextValue();
            } else {
                throw generateError(name + " element was not found in the <data> element");
            }
            output = output + (coefficient * math:pow(independent, exponent));
        } else if (elementName.contains("CategoricalPredictor")) {
            string name = predictor@["name"];
            string value = predictor@["value"];
            var coefficient, _ = <float>predictor@["coefficient"];

            if (!hasChildElement(data, name)) {
                throw generateError(name + " element was not found in the data element");
            }
            string independent = data.selectChildren(name).getTextValue();

            if (independent == value) {
                output = output + coefficient;
            }
        } else {
            // TODO decide what to do.
            throw generateError("invaid element: " + predictor.getElementName());
        }
        i = i + 1;
    }
    return output;
}
