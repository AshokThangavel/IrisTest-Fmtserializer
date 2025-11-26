Class IrisTest.Format.Serializer Extends %RegisteredObject
{
Property YAMLStream As %Stream.TmpCharacter;

Property IsVerbose As %Boolean [ InitialExpression = 0 ];

Property UnitTestId As %Integer;

Property ResultSet As %SQL.StatementResult;

Parameter UTGbl As STRING = "^UnitTest.Result";

ClassMethod GenerateYAML(pUnitTestId As %Integer = 0, pResultType As %String = "all", pIsVerbose As %Integer = 0) As %Stream.TmpCharacter
{
	if 'pUnitTestId||('$data(@..#UTGbl(pUnitTestId))) {
		return $$$ERROR($$$GeneralError,"Unit test id is invalid")
	}
	set obj = ..%New(pUnitTestId)
	do obj.SetResultSetObj(pResultType)
	if obj.ResultSet.%SQLCODE {
		return $$$ERROR($$$GeneralError,obj.ResultSet.%Message)
	}
	return obj.YAML()
}

ClassMethod GenerateJSON(pUnitTestId As %Integer = 0, pResultType As %String = "all", pIsVerbose As %Integer = 0) As %DynamicObject
{
	if 'pUnitTestId||('$data(@..#UTGbl(pUnitTestId))) {
		return $$$ERROR($$$GeneralError,"Unit test id is invalid")
	}
	set obj = ..%New(pUnitTestId,pIsVerbose)
	do obj.SetResultSetObj(pResultType)
	if obj.ResultSet.%SQLCODE {
		return $$$ERROR($$$GeneralError,obj.ResultSet.%Message)
	}
	return obj.JSON()
}

Method SetResultSetObj(pResultType As %String = "")
{
	set ..ResultSet = $Method(,$Select(pResultType="failed":"Failed",pResultType="passed":"Passed",1:"All")_"CasesFunc",..UnitTestId)
}

Method YAML() As %Stream.TmpCharacter
{
	set tResult= ..ResultSet
    set (yaml,currentID,currentSuite,currentTestcase) = ""
    while tResult.%Next() {
        if currentID = "" {
            set currentID = ..UnitTestId
            do ..YAMLStream.WriteLine("unitTest:")
            do ..YAMLStream.WriteLine("  id: "_..UnitTestId)
            do ..YAMLStream.WriteLine("  namespace: """_tResult.namespace_"""")
            do ..YAMLStream.WriteLine("  duration: "_tResult.duration)
            do ..YAMLStream.WriteLine("  testDateTime: """_tResult.testDateTime_"""")
            do ..YAMLStream.WriteLine( "")
            do ..YAMLStream.WriteLine("  results:")
        }
        if tResult.suiteName '= currentSuite {
            set currentSuite = tResult.suiteName
            set currentTestcase = ""
            do ..YAMLStream.WriteLine("    - suiteName: """_tResult.suiteName_"""")
            do ..YAMLStream.WriteLine("      testcases:")
        }
        if tResult.testcaseName '= currentTestcase {
            set currentTestcase = tResult.testcaseName
            do ..YAMLStream.WriteLine("        - testcaseName: """_tResult.testcaseName_"""")
            do ..YAMLStream.WriteLine("          methods:")
        }
        do ..YAMLStream.WriteLine("            - methodName: """_tResult.methodName_"""")
        //do ..YAMLStream.WriteLine("              testMethod: """_tResult.testMethod_"""")
        do ..YAMLStream.WriteLine("              assertAction: """_tResult.assertAction_"""")
        do ..YAMLStream.WriteLine("              assertCounter: "_tResult.assertCounter)
        //do ..YAMLStream.WriteLine("              assertDescription: |")
        //do ..YAMLStream.WriteLine("                "_$replace(tResult.assertDescription, $c(10), $c(10)_"                "))
        do ..YAMLStream.WriteLine("              assertLocation: """_tResult.assertLocation_"""")
    }
    return ..YAMLStream
}

Method JSON() As %DynamicObject
{
	set tResult= ..ResultSet
    set unitTest = {}
    set unitTest.results = []
    set (previousID,currentSuite,currentTestcase,suiteObj,testcaseObj) = ""

    while tResult.%Next() {
        if previousID = "" {
            set unitTest.id = ..UnitTestId
            set unitTest.namespace = tResult.namespace
            set unitTest.duration = tResult.duration
            set unitTest.testDateTime = tResult.testDateTime
        }
        set previousID = ..UnitTestId
        if tResult.suiteName '= currentSuite {
            set currentSuite = tResult.suiteName
            set suiteObj = {
                "suiteName": (currentSuite),
                "testcases": []
            }
            do unitTest.results.%Push(suiteObj)
            set currentTestcase = ""
        }
        if tResult.testcaseName '= currentTestcase {
            set currentTestcase = tResult.testcaseName
            set testcaseObj = {
                "testcaseName": (currentTestcase),
                "methods": []
            }
            do suiteObj.testcases.%Push(testcaseObj)
        }
        set methodObj = {
            "methodName": (tResult.methodName),
            "testMethod": (tResult.testMethod),
            "assertAction": (tResult.assertAction),
            "assertCounter": (tResult.assertCounter),
            "assertDescription": (tResult.assertDescription),
            "assertLocation": (tResult.assertLocation)
        }
        do testcaseObj.methods.%Push(methodObj)
    }
	return unitTest
}

Query FailedCases(pInstance As %Integer) As %SQLQuery(ROWSPEC = "namespace:%String,duration:%String,testDateTime:%String,suiteName:%String,testcaseName:%String,methodName:%String,testMethod:%String,assertAction:%String,assertCounter:%Integer,assertDescription:%String,assertLocation:%String", SELECTMODE = "DISPLAY")
{

SELECT
tinstance.Namespace AS namespace,
tinstance.Duration AS duration,
tinstance.DateTime AS testDateTime,
tsuite.Name AS suiteName,
tcase.Name AS testcaseName,
tmethod.Name AS methodName,
tassert.TestMethod AS testMethod,
tassert.Action AS assertAction,
tassert.Counter AS assertCounter,
tassert.Description AS assertDescription,
tassert.Location AS assertLocation
FROM
%UnitTest_Result.TestInstance tinstance
JOIN %UnitTest_Result.TestSuite tsuite ON tsuite.TestInstance=tinstance.ID
JOIN %UnitTest_Result.TestCase tcase  ON tcase.TestSuite=tsuite.ID
JOIN %UnitTest_Result.TestMethod tmethod ON tmethod.TestCase=tcase.ID
JOIN %UnitTest_Result.TestAssert tassert ON tassert.TestMethod=tmethod.ID
WHERE tinstance.ID=:pInstance AND tassert.Status='failed'
}

Query PassedCases(pInstance As %Integer) As %SQLQuery(ROWSPEC = "namespace:%String,duration:%String,testDateTime:%String,suiteName:%String,testcaseName:%String,methodName:%String,testMethod:%String,assertAction:%String,assertCounter:%Integer,assertDescription:%String,assertLocation:%String", SELECTMODE = "DISPLAY")
{

SELECT
tinstance.Namespace AS namespace,
tinstance.Duration AS duration,
tinstance.DateTime AS testDateTime,
tsuite.Name AS suiteName,
tcase.Name AS testcaseName,
tmethod.Name AS methodName,
tassert.TestMethod AS testMethod,
tassert.Action AS assertAction,
tassert.Counter AS assertCounter,
tassert.Description AS assertDescription,
tassert.Location AS assertLocation
FROM
%UnitTest_Result.TestInstance tinstance
JOIN %UnitTest_Result.TestSuite tsuite ON tsuite.TestInstance=tinstance.ID
JOIN %UnitTest_Result.TestCase tcase  ON tcase.TestSuite=tsuite.ID
JOIN %UnitTest_Result.TestMethod tmethod ON tmethod.TestCase=tcase.ID
JOIN %UnitTest_Result.TestAssert tassert ON tassert.TestMethod=tmethod.ID
WHERE tinstance.ID=:pInstance AND tassert.Status='passed'
}

Query SkippedCases(pInstance As %Integer) As %SQLQuery(ROWSPEC = "namespace:%String,duration:%String,testDateTime:%String,suiteName:%String,testcaseName:%String,methodName:%String,testMethod:%String,assertAction:%String,assertCounter:%Integer,assertDescription:%String,assertLocation:%String", SELECTMODE = "DISPLAY")
{

SELECT
tinstance.Namespace AS namespace,
tinstance.Duration AS duration,
tinstance.DateTime AS testDateTime,
tsuite.Name AS suiteName,
tcase.Name AS testcaseName,
tmethod.Name AS methodName,
tassert.TestMethod AS testMethod,
tassert.Action AS assertAction,
tassert.Counter AS assertCounter,
tassert.Description AS assertDescription,
tassert.Location AS assertLocation
FROM
%UnitTest_Result.TestInstance tinstance
JOIN %UnitTest_Result.TestSuite tsuite ON tsuite.TestInstance=tinstance.ID
JOIN %UnitTest_Result.TestCase tcase  ON tcase.TestSuite=tsuite.ID
JOIN %UnitTest_Result.TestMethod tmethod ON tmethod.TestCase=tcase.ID
JOIN %UnitTest_Result.TestAssert tassert ON tassert.TestMethod=tmethod.ID
WHERE tinstance.ID=:pInstance AND tassert.Status='skipped'
}

Query AllCases(pInstance As %Integer) As %SQLQuery(ROWSPEC = "namespace:%String,duration:%String,testDateTime:%String,suiteName:%String,testcaseName:%String,methodName:%String,testMethod:%String,assertAction:%String,assertCounter:%Integer,assertDescription:%String,assertLocation:%String", SELECTMODE = "DISPLAY")
{

SELECT
tinstance.Namespace AS namespace,
tinstance.Duration AS duration,
tinstance.DateTime AS testDateTime,
tsuite.Name AS suiteName,
tcase.Name AS testcaseName,
tmethod.Name AS methodName,
tassert.TestMethod AS testMethod,
tassert.Action AS assertAction,
tassert.Counter AS assertCounter,
tassert.Description AS assertDescription,
tassert.Location AS assertLocation
FROM
%UnitTest_Result.TestInstance tinstance
JOIN %UnitTest_Result.TestSuite tsuite ON tsuite.TestInstance=tinstance.ID
JOIN %UnitTest_Result.TestCase tcase  ON tcase.TestSuite=tsuite.ID
JOIN %UnitTest_Result.TestMethod tmethod ON tmethod.TestCase=tcase.ID
JOIN %UnitTest_Result.TestAssert tassert ON tassert.TestMethod=tmethod.ID
WHERE tinstance.ID=:pInstance
}

Method %OnNew(pUnitTestId As %Integer = 0, pIsVerbose As %Integer = 0) As %Status
{
	set ..UnitTestId = pUnitTestId
	set ..IsVerbose = pIsVerbose
	return $$$OK
}

}