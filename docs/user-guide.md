# Ballerina PMML API - User Guide

### Public Functions of 'ballerina.pmml' package

#### Contents
* [public function predict (xml pmml, xml data) (any)](#public-function-predict-(xml-pmml,-xml-data)-(any))
* [public function isValid (xml pmml) (boolean isValid, error err)](#public-function-isvalid-(xml-pmml)-(boolean-isvalid,-error-err))
* [public function isPredictable (xml pmml) (boolean isPredictable, error err)](#public-function-ispredictable-(xml-pmml)-(boolean-ispredictable,-error-err))
* [public function isDataElementValid (xml data) (boolean isDataElementValid, error err)](#public-function-isdataelementvalid-(xml-data)-(boolean-isdataelementvalid,-error-err))
* [public function getModelType (xml pmml) (string)](#public-function-getmodeltype-(xml-pmml)-(string))
* [public function getVersion (xml pmml) (float)](#public-function-getversion-(xml-pmml)-(float))
* [public function readXMLFromFile (string filePath) (xml)](#public-function-readxmlfromfile-(string-filepath)-(xml))

##### public function predict (xml pmml, xml data) (any)
Predicts the outcome based on the machine learning model defined in the PMML and the independent values entered by the user.

**Parameters:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| pmml | **xml** | The PMML element |
| data | **xml** | The independent values entered by the user |

**Returns:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
|  | **any** | The predicted outcome |

##### public function isValid (xml pmml) (boolean isValid, error err)
Checks whether a given PMML element is valid or not. If the element is **not** valid, the function throws an error along with the boolean with a message of why the PMML element is not valid, otherwise the error returned will be `null` if the PMML element is a valid one.

**Parameters:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| pmml | **xml** | The PMML element |

**Returns:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| isValid | **boolean** | Returns **true** if the PMML element is a valid one |
| err| **error** | Returns **null** if the PMML is a valid one |

##### public function isPredictable (xml pmml) (boolean isPredictable, error err)
Checks whether a given PMML element can be used to predict values in this API or not. This function was added because the API is a proof-of-concept and is still very limited in parsing PMML files.

**Parameters:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| pmml | **pmml** | The PMML element |

**Returns:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| isPredictable | **boolean** | Returns **true** if the PMML element can be used to predict an outcome in this API |
| err | **error** | Returns **null** if the PMML element is predictable using the API |

##### public function isDataElementValid (xml data) (boolean isDataElementValid, error err)
Checks whether a `<data>` element entered by the user follows the valid XML schema or not.

**Parameters:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| data| **xml** | The `<data>` element |

**Returns:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| isDataElementValid | **boolean** | Returns **true** if the given `<data>` element follows the XML schema |
| err| **error** | Returns **null** if the data element is valid |

##### public function getModelType (xml pmml) (string)
Gets the *element name* of the model element a PMML element is using.

**Parameters:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| pmml | **xml** | The PMML element |

**Returns:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
|  | **string** | The element name of the model element in the PMML |

##### public function getVersion (xml pmml) (float)
Returns the version that a given PMML element is defined in.

**Parameters:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| pmml | **xml** | The PMML element |

**Returns:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
|  | **float** | The version number |

##### public function readXMLFromFile (string filePath) (xml)
Reads a file in a given path and converts the file's content into a Ballerina `xml` type.

**Parameters:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
| filePath | **string** | The relative path in which the file is stored |

**Returns:**

| Parameter Name| Data Type | Description |
| :--- | :--- | :--- |
|  | **xml** | The file's content as an `xml` variable |