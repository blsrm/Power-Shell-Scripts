'----------Description----------
'SQL server consistency check script
'
'Script usage:
'Windows authentication    cscript SqlChecker.vbs [logs folder] <sql server[\instance]>
'SQL authentication        cscript SqlChecker.vbs [logs folder] <sql server[\instance]> <username> <password>
'
'Examples:
'1. To check all SQL instances on the server
'cscript SqlChecker.vbs c:\logs 192.168.1.1
'
'2. To check specific instance using SQL credentials
'cscript SqlChecker.vbs c:\logs 192.168.1.1\instance1 sa password
'
'3. To check default instance only without writing log file
'cscript SqlChecker.vbs 192.168.1.1\mssqlserver
'
'4. To check SQL instance using port 1433
'cscript SqlChecker.vbs 192.168.1.1,1433
'
'
'To exclude DBs or instances from the check, make corresponding entries in the settings section below
'
'Return codes:
'0 - Success
'1 - Wrong command line syntax
'2 - Unable to connect SQL server
'3 - All instances have been excluded from the check
'4 - Error occurred while getting list of databases (query [master].[sys].[databases] execution failed)
'5 - Unknown error
'6 - One or more databases are not accessible
'
'
'Version 1.1
'July 2015
'
'Created by:
'Vyacheslav Kuznetsov
'
'Veeam Support
'----------Variables and constants declaration----------
Option Explicit
Dim gsServer, gbIsWindowsAuth, gsSqlUser, gsPassword
Dim gLog, gInstancesToProcess, gDBsToExclude, gInstancesToExclude

Const SELECT_ALL_DBS = "SELECT [name] FROM [master].[sys].[databases]"
Const LOG_LEVEL_NOLOG = 0
Const LOG_LEVEL_STANDARD = 1
Const LOG_LEVEL_TRACE = 2

Const EXIT_CODE_SUCCESS = 0
Const EXIT_CODE_WRONG_SYNTAX = 1
Const EXIT_CODE_CANT_CONNECT = 2
Const EXIT_CODE_ALL_EXCLUDED = 3
Const EXIT_CODE_CANT_QUERY_DBS = 4
Const EXIT_CODE_ERROR_UNKNOWN = 5
Const EXIT_CODE_SOME_DBS_UNAVAIL = 6

Set gDBsToExclude = New Stack
Set gInstancesToExclude = New Stack
'----------Settings----------
'Exclude database
'Example:
'To exclude database dbname uncomment the line below:
'gDBsToExclude.Push "dbname"

'Exclude sql instance
'Example:
'To exclude instance, uncomment the line below and put in your instance name:
'gInstancesToExclude.Push "instancename"
'To exclude default instance, uncomment the line below:
'gInstancesToExclude.Push "MSSQLSERVER"
'----------Main----------
Set gLog = New LogWriter
gLog.LogLevel=LOG_LEVEL_TRACE

ParseCommandLineOptions
gLog "===================="
gLog "Starting SQL checker script"

Set gInstancesToProcess = New Stack
GetInstances gsServer, gInstancesToProcess, gInstancesToExclude
CheckInstances gInstancesToProcess
Quit EXIT_CODE_SUCCESS

'----------Functions----------
Sub ParseCommandLineOptions
	Dim sLogsFolder
	Select Case WScript.Arguments.Count
	Case 1:
		gsServer=WScript.Arguments(0)
		gbIsWindowsAuth=True
	Case 2:
		sLogsFolder = WScript.Arguments(0)
		gsServer=WScript.Arguments(1)
		gLog.GenerateLog sLogsFolder,gsServer
		gbIsWindowsAuth=True
	Case 3:
		gsServer=WScript.Arguments(0)
		gsSqlUser=WScript.Arguments(1)
		gsPassword=WScript.Arguments(2)
		gbIsWindowsAuth=False
	Case 4:
		sLogsFolder = WScript.Arguments(0)
		gsServer=WScript.Arguments(1)
		gLog.GenerateLog sLogsFolder,gsServer
		gsSqlUser=WScript.Arguments(2)
		gsPassword=WScript.Arguments(3)
		gbIsWindowsAuth=False
	Case Else:
		gLog.Error "Wrong number of arguments - " & WScript.Arguments.Count
		PrintUsage
		Quit EXIT_CODE_WRONG_SYNTAX
	End Select
End Sub
Sub PrintUsage
	gLog.Write "Script usage:"
	gLog.Write "Windows authentication: cscript SqlChecker.vbs [logs folder] <sql server[\instance]>"
	gLog.Write "SQL authentication: cscript SqlChecker.vbs [logs folder] <sql server[\instance]> <username> <password>"
End Sub

Sub GetInstances(ByVal sServer, ByRef instanceList, ByRef excludeList)
	Dim oShell, oExec, stdOut, sLine, sInstanceName, iPos, sCont, sCommand, bExcluded
	iPos = InStr(sServer,"\")
	'instance specified
	If iPos>0 Then
		sInstanceName = Mid(sServer, iPos+1)
		If LCase(sInstanceName) = "mssqlserver" Then
			sServer = Left(sServer, iPos-1)
		End If
		gLog "Instance to check " & sServer
		instanceList.Push sServer
		Exit Sub
	End If
	'port specified
	If InStr(sServer,",")>0 Then
		gLog "Instance to check " & sServer
		instanceList.Push sServer
		Exit Sub
	End If
	gLog "Enumerating SQL instances on " & gsServer
	Set oShell = CreateObject("WScript.Shell")
	sCommand = "sc \\" & sServer & " query"
	Set oExec = oShell.Exec(sCommand)
	Set stdOut = oExec.StdOut
	sCont = stdOut.ReadAll
	bExcluded = False
	For Each sLine In Split(sCont,vbCrLf)
		sLine = Trim(sLine)
		iPos = InStr(1,sLine,": MSSQLSERVER",1)
		If iPos>0 Then
			If Len(sLine) = iPos + 12 Then
				If excludeList.Contains("MSSQLSERVER") Then
					gLog vbTab & "Excluded " & sServer & " (default instance)"
					bExcluded = True
				Else
					gLog vbTab & sServer & " (default instance)"
					instanceList.Push sServer
				End If
			End If
		Else
			iPos = InStr(1,sLine,": MSSQL$",1)
			If iPos>0 Then
				sInstanceName = Mid(sLine, iPos+8)
				If InStr(1,sLine,"MICROSOFT##",1)>0 Then
					gLog vbTab & "Excluding system instance " & sServer & "\" & sInstanceName
				ElseIf excludeList.Contains(sInstanceName) Then
					gLog vbTab & "Excluded " & sServer & "\" & sInstanceName
					bExcluded = True
				Else
					gLog vbTab & sServer & "\" & sInstanceName
					instanceList.Push sServer & "\" & sInstanceName
				End If
			End If
		End If
	Next
	If instanceList.Count=0 Then
		If bExcluded Then
			gLog.Error "All instances were excluded"
			Quit EXIT_CODE_ALL_EXCLUDED
		Else
			gLog.Error "Failed to enumerate instances on SQL server"
			gLog.Trace "Output of the command '" & sCommand & "':"
			gLog.Trace sCont
			Quit EXIT_CODE_CANT_CONNECT
		End If
	End If
End Sub

Sub CheckInstances(ByRef instanceList)
	Dim sInstanceName
	Do While instanceList.Pop(sInstanceName) = True
		CheckInstance sInstanceName
	Loop
End Sub
Sub CheckInstance(sInstance)
	Dim sqlConnection, sConnString, iErrCode, failedDBs, sDBName
	'Create connection String
	gLog ""
	gLog "Checking " & sInstance
	
	'Preparing SQL connection string
	sConnString = "Provider=SQLOLEDB.1;Initial Catalog=master;Server=" & sInstance
	If gbIsWindowsAuth Then
		sConnString = sConnString & ";Integrated Security=SSPI"
		gLog "Authentication: Windows. User: " & GetCurrentUser
	Else
		sConnString = sConnString & ";user id='" & gsSqlUser & "';password='" & gsPassword & "'"
		gLog "Authentication: SQL. User: " & gsSqlUser
	End If
	gLog.Trace "Connection string: " & RemovePass(sConnString)

	'Trying to connect SQL server
	gLog "Connecting to SQL instance..."
	iErrCode = ConnectSql(sqlConnection, sConnString)
	If iErrCode <> EXIT_CODE_SUCCESS Then
		Quit iErrCode
	End If
	gLog.Trace "Connected successfully"

	'Query all databases state
	Set failedDBs = New Stack
	failedDBs.Count
	iErrCode = QueryDBsState(sqlConnection, failedDBs)
	If iErrCode = EXIT_CODE_SUCCESS Then
		gLog "All databases are accessible on " & sInstance & "."
	Else
		If iErrCode = EXIT_CODE_SOME_DBS_UNAVAIL Then
			gLog.Error failedDBs.Count & " database(s) in failed state:"
			Do While failedDBs.Pop(sDBName)
				gLog.Error vbTab & sDBName
			Loop
		End If
		Quit iErrCode
	End If
End Sub
Function ConnectSql(ByRef oConn, sConnString)
	Set oConn = CreateObject("ADODB.Connection")
	On Error Resume Next
		oConn.Open sConnString
		If Err.Number = 0 Then
			ConnectSql = EXIT_CODE_SUCCESS
		Else
			gLog.Error "Error occurred while connecting SQL server " & Err.Number & " " & Err.Description
			ConnectSql = EXIT_CODE_CANT_CONNECT
		End If
	On Error GoTo 0
End Function
Function QueryDBsState(oConn, failedList)
	Dim oCom, oRS, sDbName
	Set oCom = CreateObject("ADODB.Command")
	Set oCom.ActiveConnection = oConn
	oCom.CommandText = SELECT_ALL_DBS
	gLog "Getting databases list..."
	gLog.Trace "Executing query: " & SELECT_ALL_DBS
	On Error Resume Next
		Set oRS = oCom.Execute
		If Err.Number<>0 Then
			Set oCom = Nothing
			Set oRS = Nothing
			gLog.Error "Error occurred while getting DBs list. Query: " & SELECT_ALL_DBS & " Error: " & Err.Number & " " & Err.Description
			QueryDBsState=EXIT_CODE_CANT_QUERY_DBS
			Exit Function
		End If
	On Error GoTo 0
	gLog.Trace "Query executed successfully"
	gLog "Trying to access each database..."
	Do While Not oRS.EOF
		sDbName = oRS.Fields(0)
		If gDBsToExclude.Contains(sDbName) Then
			gLog.Trace vbTab & "Database " & sDbName & " is excluded"
		Else
			If CheckDBAvailability(oConn, sDbName)=False Then
				failedList.Push sDbName
			End If
		End If
		oRS.MoveNext
	Loop
	If failedList.Count = 0 Then
		QueryDBsState = EXIT_CODE_SUCCESS
	Else
		QueryDBsState = EXIT_CODE_SOME_DBS_UNAVAIL
	End If
End Function
Function CheckDBAvailability(oConn, sName)
	Dim oCom
	Set oCom = CreateObject("ADODB.Command")
	oCom.ActiveConnection = oConn
	oCom.CommandText = "use [" & sName & "]"
	On Error Resume Next
		gLog.Trace vbTab & "Executing query: " & oCom.CommandText
		oCom.Execute
		If Err.Number <> 0 Then
			gLog.Error "Database " & sName & " can't be accessed. Execution of the query '" & oCom.CommandText & "' failed with the error: " & Err.Number & " " & Err.Description
			CheckDBAvailability=False
		Else
			gLog.Trace vbTab & "Database " & sName & " is available"
			CheckDBAvailability=True
		End If
	On Error GoTo 0
End Function
Function GetCurrentUser
	Dim oNet
	On Error Resume Next
		Set oNet = CreateObject("WScript.NetWork")
		GetCurrentUser = oNet.UserDomain & "\" & oNet.UserName
	On Error GoTo 0
End Function
Function RemovePass(ByVal sConnStr)
	Dim iPos
	iPos = InStr(1,sConnStr,"';password='",1)
	If iPos > 0 Then
		RemovePass=Left(sConnStr,iPos+11) & "***'"
	Else
		RemovePass=sConnStr
	End If
End Function
Function GetExitCodeDescription(iExitCode)
	Select Case iExitCode
		Case EXIT_CODE_SUCCESS:
			GetExitCodeDescription = "Success"
		Case EXIT_CODE_WRONG_SYNTAX:
			GetExitCodeDescription = "Wrong command line syntax"
		Case EXIT_CODE_CANT_CONNECT:
			GetExitCodeDescription = "Unable to connect SQL server"
		Case EXIT_CODE_CANT_QUERY_DBS:
			GetExitCodeDescription = "Error occurred while getting list of databases"
		Case EXIT_CODE_ERROR_UNKNOWN:
			GetExitCodeDescription = "Unknown error"
		Case EXIT_CODE_SOME_DBS_UNAVAIL:
			GetExitCodeDescription = "One or more databases are not accessible"
	End Select
End Function
Sub Quit(iExitCode)
	On Error Resume Next
	If Not IsNumeric(iExitCode) Then iExitCode = EXIT_CODE_ERROR_UNKNOWN
	gLog "Exit code: " & iExitCode & ". " & GetExitCodeDescription(iExitCode)
	Set gLog = Nothing
	WScript.Quit iExitCode
End Sub
'----------Custom types----------
Class Stack
	Private m_Content, m_Count
	Private Sub class_initialize
		m_Count=0
		ReDim m_Content(0)
	End Sub
	Public Function Contains(ByVal sElem)
		Dim i
		sElem = LCase(Trim(sElem))
		If m_Count > 0 Then
			For i=0 To m_Count-1
				If LCase(m_Content(i))=sElem Then
					Contains = True
					Exit Function
				End If
			Next
		End If
		Contains = False
	End Function
	Public Sub Push(value)
		If m_Count>0 Then
			ReDim Preserve m_Content(m_Count)
		End If
		m_Content(m_Count)=value
		m_Count = m_Count+1
	End Sub
	Public Function Pop(ByRef outValue)
		If m_Count=0 Then
			Pop=False
			Exit Function
		End If
		m_Count = m_Count-1
		outValue = m_Content(m_Count)
		If m_Count>0 Then
			ReDim Preserve m_Content(m_Count-1)
		End If
		Pop = True
	End Function
	Public Property Get Count
		Count = m_Count
	End Property
End Class
Class LogWriter
'Declaring variables
	Private oFSO,oTextFile,sPath,sCurFolder,iLogLevel,bLoggingEnabled
	Public Verbose,FileOpenMethod,FileEncoding,AddDate
'Methods 
	Private Sub class_initialize
		Const FILE_OPEN_WRITE=2
		Const FILE_OPEN_APPEND=8
		Const ENCODING_ASCII=0
		Const ENCODING_UNICODE=-1
		Const ENCODING_DEFAULT=-2
		iLogLevel=LOG_LEVEL_STANDARD
		Set oFSO=WScript.CreateObject("Scripting.FileSystemObject")
		Verbose=False
		FileOpenMethod=FILE_OPEN_APPEND
		FileEncoding=ENCODING_DEFAULT
		AddDate=True
		sCurFolder=Left(WScript.ScriptFullName,Len(WScript.ScriptFullName)-Len(WScript.ScriptName))
		If LCase(Right(WScript.FullName,Len(WScript.FullName)-Len(WScript.Path)-1))="cscript.exe" Then	Verbose=True
		bLoggingEnabled = False
	End Sub
	Private Sub class_terminate
		If VarType(oTextFile)=9 Then	oTextFile.Close
		Set oFSO=Nothing
	End Sub
	Private Sub AssignFile
		On Error Resume Next
		Set oTextFile=oFSO.OpenTextFile(sPath,FileOpenMethod,True,FileEncoding)
		If Err.Number=0 Then
			bLoggingEnabled=True
		End If
	End Sub
	Private Sub DoWrite(ByVal sText)
		sText=Replace(sText,vbCrLf,"")
		If Verbose And iLogLevel>0 Then WScript.Echo sText
		If iLogLevel=0 Or Not bLoggingEnabled Then Exit Sub
		If VarType(oTextFile)=0 Then AssignFile
		If AddDate Then
			sText="[" & Now & "] " & sText
		End If
		oTextFile.WriteLine sText
	End Sub
	
	Public Sub GenerateLog(sLogsFolder,ByVal sServer)
		Dim iPos
		If Not oFSO.FolderExists(sLogsFolder) Then
			Exit Sub
		End If
		If InStrRev(sLogsFolder,"\")<Len(sLogsFolder) Then
			sLogsFolder = sLogsFolder & "\"
		End If
		iPos = InStr(sServer, "\")
		If iPos>0 Then
			sServer = Left(sServer,iPos-1)
		End If
		sServer = Replace(sServer,".","_")
		sServer = Replace(sServer,":","_")
		sPath = sLogsFolder & "SqlChecker_" & sServer & ".log"
		AssignFile
	End Sub
	Public Sub Write(sText)
		DoWrite sText
	End Sub
	Public Sub Error(sText)
		DoWrite "Error " & sText
	End Sub
	Public Default Sub Info(sText)
		DoWrite "Info " & sText
	End Sub
	Public Sub Trace(sText)
		If iLogLevel=LOG_LEVEL_TRACE Then Info sText
	End Sub
	'Properties
	Public Property Get CurFolder
		CurFolder=sCurFolder
	End Property
	Public Property Let LogLevel(iValue)
		If IsNumeric(iValue) Then
			If iValue>=0 And iValue<=2 And VarType(oTextFile)=0 Then
				iLogLevel=iValue
			End If
		End If
	End Property
	Public Property Get LogLevel
		LogLevel=iLogLevel
	End Property
	Public Property Get Path
		Path = sPath
	End Property
End Class
