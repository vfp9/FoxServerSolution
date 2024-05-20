#include "FoxServer.h"
** CLASE HELPER PARA LAS IMPLEMENTACIONES REST
Define Class ControllerHelper As Session
	Hidden oUtility, oDB, bDebugMode, cLang, cEstado, cMensaje
	cQuery = Space(1)

	Procedure Init
		this.oUtility = CreateObject("APIUtility")
		** Instancia para las conexiones a bases de datos
		this.oDB = CreateObject("DBConnection")
		this.oDB.oUtility = this.oUtility
		this.bDebugMode = .F.
		this.cEstado  = 'estado'
		this.cMensaje = 'mensaje'
	EndProc
	
	Procedure SetLang(tcLang as String)
		this.cLang = tcLang
		If Lower(this.cLang) = 'en'
			this.cEstado  = 'status'
			this.cMensaje = 'message'
		endif
	EndProc
	
	Function GetLang as string
		Return this.cLang
	EndFunc
	
&& ------------------------------------------------------ &&
&& API para la base de datos.
&& ------------------------------------------------------ &&
	Function OpenConnection
		Return this.oDB.OpenConnection()
	Endfunc

	Procedure CloseConnection
		this.oDB.CloseConnection()
	Endproc

	Function GetHandle
		Return this.oDB.GetHandle()
	EndFunc

	Function ExecuteQuery(tcQuery) as object
		If Empty(tcQuery) and Empty(this.cQuery)
			this.log(LOG_ERROR, "ExecuteQuery(): Can't run an empty query")
			Return CreateObject("Collection")
		EndIf
		If Empty(tcQuery)
			tcQuery = this.cQuery
		EndIf
		Return this.oDB.ExecuteQuery(tcQuery)
	EndFunc

	Function QueryToJSON(tcQuery)
		If Empty(tcQuery) and Empty(this.cQuery)
			this.log(LOG_ERROR, "QueryToJson(): Can't run an empty query")
			Return 'null'
		EndIf
		If Empty(tcQuery)
			tcQuery = this.cQuery
		EndIf
		Return this.oDB.QueryToJSON(tcQuery)
	EndFunc
	
	Function ExecuteNonQuery(tcQuery)
		If Empty(tcQuery) and Empty(this.cQuery)
			this.log(LOG_ERROR, "ExecuteNonQuery(): Can't run an empty query")
			Return .F.
		EndIf
		If Empty(tcQuery)
			tcQuery = this.cQuery
		EndIf
		Return this.oDB.ExecuteNonQuery(tcQuery)
	EndFunc

	Function GetLastID(tcCustomQuery)
		Return this.oDB.GetLastID(tcCustomQuery)
	EndFunc
	
	Procedure SetConnectionString(tcConStr)
		this.oDB.SetConnectionString(tcConStr)
	EndProc
	
	Function GetSQLError as string
		Return this.oDB.GetLastError()
	EndFunc	

&& ------------------------------------------------------ &&
&& API para Utilerías
&& ------------------------------------------------------ &&
	Function LoadJsonFox as Boolean
		Return this.oUtility.LoadJsonFox()
	Endfunc

	Function EscapeCharsToJSON(tcStream) as string
		Return this.oUtility.EscapeCharsToJSON(tcStream)
	EndFunc
	
	Function GetJsonResponse(tcEstado, tcData as memo, tcMessage as memo) as memo
		Return Textmerge('{"<<this.cEstado>>": "<<tcEstado>>", "data": <<Iif(Empty(tcData) OR IsNull(tcData), "null", tcData)>>, "<<this.cMensaje>>": "<<this.EscapeCharsToJSON(tcMessage)>>"}')
	EndFunc

	Function GetExceptionMessage(toException)
		Return this.oUtility.GetExceptionMessage(toException)
	EndFunc
	
	procedure Log(tnType, tcMessage)
		this.oUtility.log(tnType, tcMessage)
	EndProc
	
	Procedure SetLogFile(tcLogFile)
		this.oUtility.SetLogFile(tcLogFile)
	EndProc
	
	Function CreateJWT(tvPayload as Variant, tcSecret as String, tnDuration as Integer) as string
		If Empty(tvPayload)
			Return ""
		EndIf		
		If Type('tvPayload') == 'O'
			If !this.oUtility.LoadJsonFox()
				Return ""
			EndIf
			tvPayload = _screen.json.stringify(tvPayload)
		EndIf
		Return this.oUtility.CreateJWT(tvPayload, tcSecret, tnDuration)
	EndFunc

	Function ParseJWT(tcJWT as string, tcSecret as string) as object
		If Empty(tcJWT) or Empty(tcSecret)
			Return .null.
		EndIf
		
		If Left(tcJWT, 7) == "Bearer "
			tcJWT = GetWordNum(tcJWT, 2)
		EndIf
		
		Local lcPayload, obj
		lcPayload = this.oUtility.ParseJWT(tcJWT, tcSecret)
		If Empty(lcPayload)
			Return .null.
		EndIf
		
		If !this.oUtility.LoadJsonFox()
			Return .null.
		EndIf

		obj = _screen.json.parse(lcPayload)
		=AddProperty(obj, "valid", this.DateToUnix(Datetime()) < obj.exp)
		
		Return obj
	EndFunc
	
	Function IsValidJWT(tcJWT as String, tcSecret as String) as Boolean
		Local loJWT
		loJWT = this.ParseJWT(tcJWT, tcSecret)
		If IsNull(loJWT) or !loJWT.valid
			Return .f.
		EndIf
		Return .t.
	EndFunc
	
	Function Base64URLEncode(tcInput)
		Return this.oUtility.Base64URLEncode(tcInput)
	Endfunc

	Function Base64URLDecode(tcInput)
		Return this.oUtility.Base64URLDecode(tcInput)
	EndFunc	
	
	Function ComputeHmacSha256(tcMessage, tcSecret)
		Return this.oUtility.ComputeHmacSha256(tcMessage, tcSecret)
	EndFunc
	
	Function DateToUnix(tdtDate)
		Return this.oUtility.dToUnx(tdtDate)
	Endfunc

	Function UnixToDate(tnUnixTimestamp)
		Return this.oUtility.UnxToD(tnUnixTimestamp)
	Endfunc	

	Function parseHTML(tcHTMLFile as String) as memo
		If !File(tcHTMLFile)
			Return ""
		EndIf
		* Cargar la página
		Local lcHTML, lcCode, lcResult, lcClases, lcExpressionPRG, lcHelpers
		lcHTML 	  = Strconv(FileToStr(tcHTMLFile), 11)
		lcHelpers = this.loadScriptHelpers()
		* Buscar y reemplazar las expresiones
		Do while !Empty(StrExtract(lcHTML, '<vfp:exp>', '</vfp:exp>', 1))				
			lcCode = StrExtract(lcHTML, '<vfp:exp>', '</vfp:exp>', 1)
			Try
				* Evaluar la expresión
				Text to lcExpressionPRG noshow pretext 1 textmerge
					Return Evaluate([<<lcCode>>])
					<<lcHelpers>>
				EndText
				lcResult = Transform(ExecScript(lcExpressionPRG))
			Catch to loEx
				* Añadimos el mensaje de la excepción
				lcResult = Textmerge('<<this.getHTMLExceptionMessage(loEx, tcHTMLFile)>>')
			Finally
				* Inyectar el resultado al HTML (bien sea por error o por OK)
				lcHTML = Strtran(lcHTML, '<vfp:exp>' + lcCode + '</vfp:exp>', lcResult)					
			EndTry
		EndDo

		* Buscar y reemplazar los scripts			
		Do while !Empty(StrExtract(lcHTML, '<vfp:script>', '</vfp:script>', 1))				
			lcCode 	 = StrExtract(lcHTML, '<vfp:script>', '</vfp:script>', 1)
			lcResult = this.executeScript(lcCode, lcHelpers)
			lcHTML   = Strtran(lcHTML, '<vfp:script>' + lcCode + '</vfp:script>', lcResult) && Inyectar el resultado al HTML				
		EndDo
		Return lcHTML
	EndFunc

	Function executeScript(tcCode As Memo, tcHelpers as memo, tbAddMacros as Boolean) As Object
		Local i, lcScript, lcHeaderCode, lcResult, loEx, lcFilePrefix, lcOutputFile, loClasses, ;
		loFunctions, loProcedures, lcClasses, lcFunctions, lcProcedures, lcMacros
		Store '' to lcClasses, lcFunctions, lcProcedures
		loClasses	 = this.extractFromCode(@tcCode, 'DEFINE',    'ENDDEFINE')
		loFunctions	 = this.extractFromCode(@tcCode, 'FUNCTION',  'ENDFUNC')
		loProcedures = this.extractFromCode(@tcCode, 'PROCEDURE', 'ENDPROC')
		
		lcClasses 	 = this.extractFromCollection(loClasses)
		lcFunctions	 = this.extractFromCollection(loFunctions)
		lcProcedures = this.extractFromCollection(loProcedures)
		lcHeaderCode = tcCode	
		lcFilePrefix = 'ParseHtmlOutput'
		lcOutputFile = Addbs(Fullpath(Curdir())) + lcFilePrefix + Sys(2015) + '.txt'
		lcResult 	 = "" 
		** Inyectar el early return (si lo hay)
		lcHeaderCode = Strtran(lcHeaderCode, 'fsExit()', 'fsExit()' + Chr(13) + Chr(10) + 'return ' + Chr(13) + Chr(10),1,1,1)
		
		* Eliminar los ficheros antiguos
		Try
			Delete File (lcFilePrefix  + '*.txt')
		Catch
		EndTry

		Text to lcMacros noshow
			#define HTML	TEXT TO lcOutput NOSHOW PRETEXT 15 TEXTMERGE
			#define END		ENDTEXT
		endtext		
		If tbAddMacros
			Text TO lcMacros noshow
&& -------------------------------------------------------- &&
&& Macro list (DO NOT MODIFY)
&& -------------------------------------------------------- &&
#define CRLF				Chr(13)+Chr(10)
#define QUERY				TEXT TO _screen.oInstance.oHelper.cQuery NOSHOW PRETEXT 15 TEXTMERGE
#define ENDQUERY			ENDTEXT
#define HELPER				_screen.oInstance.oHelper
#define	WRITELOG			_screen.oInstance.oHelper.Log
#define REQUEST				_screen.oInstance.oRequest
#define ROUTE				_screen.oInstance.oFoxServer.addRoute
#define CONTROLLER			_screen.oInstance.oFoxServer.addController
#define BODY				_screen.oInstance.oJson
#define _TRY				try
#define _CATCH				catch to loEx
#define _ENDTRY				endtry
#define _FINALLY			finally
#define STATUS_CODE			_screen.oInstance.oResponse.SetStatusCode
#define CONTENT_TYPE		_screen.oInstance.oResponse.SetContentType
#define CONTENT				_screen.oInstance.oResponse.SetContent
#define GET_HEADER			_screen.oInstance.oRequest.GetHeader
#define HTML_ENCODE			HELPER.EscapeCharsToJSON
#define _ERRORMSG			HTML_ENCODE(HELPER.GetExceptionMessage(loEx))
#define _ERRORSQL			HTML_ENCODE(HELPER.GetSQLError())
#define GET_METHOD			_screen.oInstance.oRequest.GetMethod
#Define GET_BODY			_screen.oInstance.GetBody
#Define GET_BODYSTR			_screen.oInstance.oRequest.GetBody
#define SET_STRCON			HELPER.SetConnectionString
#define CONNECT				HELPER.openConnection
#define DISCONNECT			HELPER.closeConnection
#define OBJ_QUERY			HELPER.executeQuery
#define EXEC_QUERY			HELPER.executeNonQuery
#define JSON_QUERY			HELPER.queryToJSON
#define GET_JSON_RESPONSE 	HELPER.getJsonResponse
#define URL_PARAM			_screen.oInstance.oRequest.GetURLParam
#Define SET_LOCATION		_screen.oInstance.oResponse.SetLocation
#Define HEADER_EXISTS		_screen.oInstance.oRequest.HeaderExists
#Define HEADER_GET			_screen.oInstance.oRequest.HeaderGet
#Define QPARAM_EXISTS		_screen.oInstance.oRequest.QueryParamExists
#Define QPARAM_GET			_screen.oInstance.oRequest.QueryParamGet
#Define MULTIPART_EXISTS	_screen.oInstance.oRequest.MultiPartExists
#Define MULTIPART_GET		_screen.oInstance.oRequest.MultiPartGet
#Define DTOUNX				HELPER.DateToUnix
#Define UNXTOD				HELPER.UnixToDate
#Define NEW_JWT				HELPER.CreateJwt
#Define GET_JWT				HELPER.ParseJwt
#Define MIME_FILE			_screen.oInstance.oResponse.SetFileName
#Define MIME_ENCODE			HELPER.EncodeMIMEFile
#Define PARSE_HTML			HELPER.ParseHTML
#Define PRINT_PDF			HELPER.frx2pdf
#Define CURSORTOJSON		_screen.oInstance.TableToJson
#Define	SET_LASTID			_screen.oInstance.SetLastID
#Define VALID_JWT			_screen.oInstance.ValidateToken
*#Define FMT					This.Format
#Define MASTERDETAILTOJSON	_screen.oInstance.MasterToJSON
#Define SET_DEBUG			HELPER.SetDebugMode
#Define NEWGUID				HELPER.GetNewGuid
#Define GET_URL				_screen.oInstance.GetURL
#Define _HOME 				ADDBS(FullPath(Curdir()))
#Define ADD_HEADER			_screen.oInstance.oResponse.AddResponseHeader
endtext
		EndIf
		
		
		Text to lcScript noshow textmerge
			<<lcMacros>>
			Local loEx as Exception
			* ========================================= *
			* COMANDOS PARA REDIRIGIR LA SALIDA
			* ========================================= *
			Set Console Off
			Set Printer to file "<<lcOutputFile>>"
			Set Device To printer
			Set Printer on
			
			On Error DO errHandler WITH ERROR(), MESSAGE(), MESSAGE(1), PROGRAM(), LINENO()
			<<lcHeaderCode>>
			ON ERROR  && Restores system error handler.
			fsExit()

			* ========================================= *
			* RESTAURAR LOS COMANDOS
			* ========================================= *
			Procedure fsExit
				Set Printer off
				Set Printer to
				Set Console On
				Set Device To screen
			EndProc
			* ========================================= *
			* FUNCIONES
			* ========================================= *
			<<lcFunctions>>
			<<tcHelpers>>
			* ========================================= *
			* PROCEDIMIENTOS
			* ========================================= *
			<<lcProcedures>>
			* ========================================= *
			* CLASES
			* ========================================= *
			<<lcClasses>>
		EndText	

		If this.bDebugMode
			this.oUtility.log(64, lcScript)
		EndIf
		
		* Ejecutar el script
		** POLICIA
		*STRTOFILE(lcScript + Chr(13)+Chr(10), 'c:\a1\prueba1\dist\FoxServer.log', 1)
		** POLICIA
		=Execscript(lcScript)
		If File(lcOutputFile)
		** POLICIA
		*STRTOFILE("POLICIA EXISTE" + Chr(13)+Chr(10), 'c:\a1\prueba1\dist\FoxServer.log', 1)
		** POLICIA
			lcResult = lcResult + Alltrim(Strtran(Filetostr(lcOutputFile), Chr(13)+Chr(10)))
			If Left(lcResult, 4) == '<br>'
				lcResult = Substr(lcResult, 5)
			EndIf
		Else
		** POLICIA
		*STRTOFILE("POLICIA NO EXISTE" + Chr(13)+Chr(10), 'c:\a1\prueba1\dist\FoxServer.log', 1)
		** POLICIA			
		EndIf

		Return lcResult
	EndFunc

	Hidden Function extractFromCollection(toCollection as Collection) as memo
		Local i, lcCode
		lcCode = ''
		For i=toCollection.count to 1 step -1
			lcCode = lcCode + Chr(13) + Chr(10) + toCollection.Item(i)
		EndFor
		Return lcCode
	EndFunc

	Hidden Function extractFromCode(tcCode As Memo, tcBeginDelim As String, tcEndDelim As String) As Memo
		Local lcCode as memo, loCodeList as Collection, lnAt
		loCodeList = CreateObject("Collection")
		
		lnAt = At(Lower(tcBeginDelim), tcCode)
		If lnAt > 0
			tcBeginDelim = Lower(tcBeginDelim)
			tcEndDelim = Lower(tcEndDelim)
		Else
			lnAt = At(tcBeginDelim, tcCode)
		EndIf

		If lnAt > 0
			Do while !Empty(StrExtract(tcCode, tcBeginDelim, tcEndDelim,1, 1))
				lcCode = tcBeginDelim + Strextract(tcCode, tcBeginDelim, tcEndDelim, 1, 1) + tcEndDelim
				loCodeList.Add(lcCode)
				tcCode = Strtran(tcCode, lcCode)
			EndDo
		EndIf

		Return loCodeList
	EndFunc

	function loadScriptHelpers as memo
		Local lcHelpers
		Text to lcHelpers noshow pretext 1
			Function run(tcProgram as String) as memo
				If Empty(tcProgram)
					Return ""
				EndIf
				If Empty(JustPath(tcProgram)) and Empty(JustExt(tcProgram))
					tcProgram = FullPath(tcProgram + '.prg')
				EndIf
				If !File(tcProgram)
					Return "The file does not exist"
				EndIf
				Return ExecScript(Strconv(FileToStr(tcProgram),11))
			endfunc
			
			Function echo(tcTexto as memo)
				? tcTexto FUNCTION 'V120'
			EndProc
			
			Function WriteConsole(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
				Local lcResult, i, lcExp
				lcResult = 'console.log('
				For i=1 to Pcount()
					lcExp = 'p' + Alltrim(Str(i))
					If i > 1
						lcResult = lcResult + ','
					EndIf
					lcResult = lcResult + '"' + Transform(Evaluate(lcExp)) + '"'
				EndFor
				lcResult = lcResult + ')'
				echo('<script>' + lcResult + '</script>')
			EndFunc

			Function loadImage(tcFileName as String) as memo
				Return Textmerge('"data:image/png;base64,<<loadBase64(tcFileName)>>"')
			EndFunc
			
			Function loadBase64(tcFileName as String) as memo
				If Empty(tcFileName) or Empty(JustExt(tcFileName))
					Return ""
				EndIf
				If Empty(JustPath(tcFileName))
					tcFileName = FullPath(tcFileName)
				EndIf
				
				If !File(tcFileName)
					Return "The file does not exist"
				EndIf
				
				Return Strconv(FileToStr(tcFileName), 13)
			EndFunc

			Function cursorToCombo(tcCursor, tcStyles)
				Local lcRows as memo
				lcRows = ""
				
				If Pcount() = 1
					tcStyles = ""
				EndIf
				
				If Empty(Field('value')) or Empty(Field('description'))
					Return ""
				EndIf

				Select (tcCursor)
				Scan
					lcRows = lcRows + fmt('<option value="{1}">{2}</option>', Evaluate(tcCursor + '.value'), Evaluate(tcCursor + '.description'))
				EndScan

				Return "<select " + tcStyles + ">" + lcRows + "</select>"
			EndFunc
			
			Function cursorToTable(tcCursor, tcStyles)
				Local lcResult, i, lnFields, lcRow, lcHeaders, lcData
				If Pcount() = 1
					tcStyles = 'border="1"'
				EndIf
				Store '' to lcResult, lcRow, lcHeaders, lcData
				
				lnFields = AFields(laFields, tcCursor)
				
				** Capturar los headers
				For i=1 to lnFields
					lcHeaders = lcHeaders + '<th>' + strtran(laFields[i,1], '_', Space(1)) + '</th>'
				EndFor
				
				Select (tcCursor)
				Scan
					lcData = ''
					For i=1 to lnFields
						lcData = lcData + fmt('<td>{1}</td>', Evaluate(tcCursor + '.' + laFields[i,1]))
					EndFor
					lcRow = lcRow + '<tr>' + lcData + '</tr>'
				EndScan

				Return '<table ' + tcStyles + '><thead><tr>' + lcHeaders + '</tr></thead> <tbody>' + lcRow + '</tbody></table>'
			EndFunc
			
			Function fmt(tcString,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11)
				Local i, lcResult, lcEval, lcPattern
				lcResult = tcString
				For i=2 to Pcount()
					lcPattern 	= '{' + Alltrim(Str(i-1)) + '}'
					lcEval 		= Alltrim(Transform(Evaluate("p" + Alltrim(Str(i)))))
					lcResult 	= Strtran(lcResult, lcPattern, lcEval)
				EndFor
				Return lcResult
			EndFunc
			
			Procedure errHandler(merror, mess, mess1, mprog, mlineno)
				?Textmerge("<b>Parse error[<<LTRIM(STR(merror))>>]:</b> <<mess>> near of <b><<mess1>></b> in line <b><<mlineno>></b>")
			ENDPROC			
		EndText
		Return lcHelpers
	EndFunc

	Function getHTMLExceptionMessage(toException as Exception, tcHTMLFile as string) as String
		Return Textmerge("<b>Parse error:</b> <<toException.Message>> in <b><<Lower(tcHTMLFile)>></b> near of <b><<toException.LineContents>></b> in line <b><<toException.LineNo>></b>")
	EndFunc
	
	Function EncodeMIMEFile(tcMIMEFile as String) as memo
		If !File(tcMIMEFile)
			Return ""
		EndIf
		Return Strconv(FileToStr(tcMIMEFile), 13)
	EndFunc
	
	Procedure SetDebugMode(tcMode)
		If !InList(Upper(tcMode), 'ON', 'OFF')
			Return
		EndIf
		this.bDebugMode = (Upper(tcMode) == 'ON')
	EndProc
	
	Function frx2pdf(tcFrxFile, tcOutputFile) as Boolean
		Local lcPDFPrinter
		lcPDFPrinter = FullPath("PrintPDF.exe")
		If !File(lcPDFPrinter)
			this.oUtility.log(LOG_ERROR, "Error in frx2pdf: executable does not exist " + lcPDFPrinter)
			Return .f.
		EndIf
		** Generar el reporte
		DECLARE LONG WinExec IN kernel32 STRING lpCmdLine, LONG nCmdShow		
		Local lcBuffer, lcBat
		lcBat = Addbs(Curdir()) + Sys(2015) + ".bat"
		Text to lcBuffer noshow textmerge
Cd <<JustPath(lcPDFPrinter)>>
PrintPDF.exe "<<tcFrxFile>>" "<<tcOutputFile>>"
		endtext
		StrToFile(lcBuffer, lcBat)
		If !File(lcBat)
			this.oUtility.log(LOG_ERROR, "Error in frx2pdf: could not create bat file " + lcBat)
			Return .F.
		EndIf
		WinExec(lcBat, 0)
		lnSeconds = Seconds() + 3
		Do while Seconds() <= lnSeconds
			If File(tcOutputFile)
				Exit
			EndIf
		EndDo
		Try
			Delete File (lcBat)
		Catch
		EndTry
		Return File(tcOutputFile)
	EndFunc

	Function GetNewGuid
		Local loGuid
		loGuid = CREATEOBJECT("scriptlet.typelib")
		Return Lower(Substr(loGuid.Guid, 2, 36))
	EndFunc
	
Enddefine