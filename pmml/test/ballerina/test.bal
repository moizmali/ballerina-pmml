package pmml.test.ballerina;

import ballerina.pmml;
import ballerina.file;
import ballerina.io;

function main (string[] args) {
    // Read PMML File and add it to an XML element.
    file:File file = {path:"pmml/test/res/LinearRegression.xml"};
    io:ByteChannel byteChannel = file.openChannel("r");
    blob bytes;
    int numberOfBytes;
    bytes, numberOfBytes = byteChannel.readBytes(1000000);
    string s = bytes.toString("UTF-8");
    var pmml, _ = <xml> s;

    // Test public functions of the API.
    println("Is PMML valid: " + pmml:isValid(pmml));
    println("Version number: " + pmml:getVersion(pmml));
    println("Model Type: " + pmml:getModelType(pmml) + "\n");

    // TODO make sure the input has a root element `<data>` for the input. Name could change accordingly.
    // TODO add proper error messages for invalid data inputs.
    // TODO add an implementation with multiple <car_location/> elements.
    // TODO in polynomial regression there can be multiple continuous values added. Add that as an implementation.
    // Execute the linear regression model.
    xml data = xml `<data>
                        <age>20</age>
                        <salary>10000</salary>
                        <car_location>carpark</car_location>
                    </data>`;
    println("Predicted Result Is: " + pmml:executeModel(pmml, data));

}
