#include "FoxServer.h"

* load all classes
Set Procedure To "Logger" 				Additive
Set Procedure To "APIUtility" 			Additive

Set Procedure To "Request" 				Additive
Set Procedure To "Response" 			Additive
Set Procedure To "Route" 				Additive
Set Procedure To "Tuple" 				Additive
Set Procedure To "TupleDictionary" 		Additive
Set Procedure To "DBConnection" 		Additive

Set Procedure To "ControllerHelper" 	Additive
Set Procedure To "ControllerCreator" 	Additive

Set Procedure To "Wrapper" 				Additive

* -------------------------------------------------------------------------------- *
* CLASE WRAPPER
* -------------------------------------------------------------------------------- *
Define Class Wrapper As Custom OlePublic
	Hidden cProgID, oInstance, oConfig, oRoutes, oControllers, bLoadedOk, cConfigFile, oUtility, cLogFile, bIsPostAndJSon, cLang, ;
	cEstado, cMensaje, cCorrecta, cMsgCorrecta, cAllowedOrigins
	
	* Public properties
	version = '0.1.4'

	Procedure LoadSettings
		This.oConfig = This.loadConfig()
		This.cProgID = This.GetKey("progid")
		this.oUtility = CreateObject("APIUtility")
		this.oUtility.SetLogFile(this.cLogFile)
		
		If Empty(This.cProgID)
			This.log(LOG_ERROR, "Key 'progid' does not exist in 'config.kvp'.")
			Return
		EndIf

		Try
			This.oInstance = Createobject(This.cProgID)
			this.oInstance.oHelper 	  = CreateObject("ControllerHelper")			
			this.oInstance.oFoxServer = CreateObject("ControllerCreator") && Inyectar el creador de Controladores
			try
				If File(this.oInstance.cEnvProg)
					Do (this.oInstance.cEnvProg)
				EndIf
			Catch to loEx
				This.Log(LOG_ERROR, "Error " + Transform(loEx.ErrorNo) + " at line " + Transform(loEx.LineNo) + ": " + loEx.Message + " in Environment program.")
			EndTry
			
			Try
				this.cLang = this.oInstance.cLang
				this.oInstance.oHelper.SetLang(this.cLang)
			Catch
				this.cLang = "es"
				this.oInstance.oHelper.SetLang("es")
			EndTry

			** CORS (Allow-Origins)
			Try
				this.cAllowedOrigins = this.oInstance.cAllowedOrigins
			Catch
				this.cAllowedOrigins = "*"
			EndTry

			If Lower(this.cLang) == 'en'
				this.cEstado 		= 'status'
				this.cMensaje 		= 'message'
				this.cCorrecta 		= 'success'
				this.cMsgCorrecta 	= 'request processed successfully'
			Else
				this.cEstado 		= 'estado'
				this.cMensaje 		= 'mensaje'
				this.cCorrecta 		= 'correcta'
				this.cMsgCorrecta 	= 'solicitud procesada correctamente'
			EndIf
			this.oInstance.AddControllers()
			this.LoadRoutesAndControllers()
		Catch To loEx
			This.Log(LOG_ERROR, "Error " + Transform(loEx.ErrorNo) + " at line " + Transform(loEx.LineNo) + ": " + loEx.Message)
		Endtry
	Endproc

	Function getUtility
		Return this.oUtility
	EndFunc 

	Hidden Procedure LoadRoutesAndControllers
		This.bLoadedOk 	  = .F.
		This.oRoutes 	  = This.oInstance.oFoxServer.oRoutes
		This.oControllers = This.oInstance.oFoxServer.oControllers

		If Empty(This.oRoutes.count) And empty(This.oControllers.count)
			This.Log(LOG_ERROR, "No Routes or Controllers were registered.")
			Return
		EndIf		
		This.bLoadedOk = .T.
	endproc

	Procedure HandleRequest(tcPath As String)
		Local lbSearchInController, lcMethod, lnHTTPCode, lcURL, lbHandled, loController, lcControllerName, lnIdx
		lcURL = tcPath

		** Añadimos el CORS (Allow Origin) antes que nada
		this.oInstance.oResponse.AddResponseHeader("Access-Control-Allow-Origin", this.cAllowedOrigins)		
		** Parsear el JSON en caso de ser una petición POST (para la instancia)
		If this.bIsPostAndJSon
			this.oInstance.ParseJsonBodyFromRequest()
		EndIf

		If Right(lcURL, 4) == '.prg'
			this.executePRGFile(lcURL)
			Return
		EndIf

		If Right(lcURL, 1) != '/'
			lcURL= lcURL+'/'
		EndIf

		If !Empty(This.oInstance.oRequest.GetUrlParam())
			lcURL = lcURL+This.oInstance.oRequest.GetUrlParam()
		EndIf

		lcMethod = Space(1)
		lbSearchInController = .T.
		lnHTTPCode = 404 && NOT FOUND
				
		** Los routes tienen prioridad sobre los controllers
		If !Isnull(This.oRoutes)
			If this.oInstance.bHandleURL				
				lbSearchInController = !this.executeManualURL(this.oInstance, lcURL)
			else
				lnIdx = This.oRoutes.GetKey(tcPath)
				If lnIdx > 0
					lbSearchInController = .F.
					Try
						Local lbSeguir
						lcMethod = This.oRoutes.Item(lnIdx)
						lbSeguir = .T.
						If !this.oInstance.MethodExists(lcMethod)
							this.setError404()
							lbSeguir = .f.
						EndIf
						If lbSeguir
							If this.oInstance.MethodExists("BeforeExecute")
								If !this.oInstance.BeforeExecute() && Método Hook BeforeExecute
									lbSeguir = .f.
								EndIf
							EndIf
							If lbSeguir
								this.oInstance.CallMethod(lcMethod)

								If this.oInstance.MethodExists("AfterExecute")
									this.oInstance.AfterExecute() && Ejecutar el método Hook AfterExecute
								EndIf
								
								If this.oInstance.oResponse.GetStatusCode() == 201 && Created
									this.oInstance.oResponse.SetLocation(Alltrim(Transform(this.oInstance.GetLastID())))
								EndIf															
							EndIf
						EndIf
					Catch to loEx
						This.SetError500("Error " + Transform(loEx.ErrorNo) + " at line " + Transform(loEx.LineNo) + ": " + loEx.Message + " in method " + lcMethod + "().")
					EndTry
				EndIf
			EndIf
		Endif

		If lbSearchInController
			If Isnull(This.oControllers)
				this.setError404()
				Return
			Endif
			Local loController, loRequest, lnOccurs, i, ;
			lbIsCustomMethod, lcCustomMethodName, lcCalledMethod, loParamsCollection

			loRequest = This.oInstance.oRequest
			lcMethod  = Upper(loRequest.GetMethod())
			** check if we have a custom endpoint eg: products/outdated-list
			lnOccurs = Occurs('/', tcPath)
			If lnOccurs > 12
				this.SetError400("Parameter overflow. You must pass a maximun of 10 parameters in the URL.")
				Return
			EndIf
			
			If lnOccurs >= 2
				loController = this.getController(Lower(GetWordNum(tcPath, 1, '/')) + 'controller')
				If IsNull(loController)
					this.setError404()
					Return
				EndIf
				If loController.bHandleURL
					If this.executeManualURL(loController, lcURL)
						Return
					EndIf
				EndIf
				lcCustomMethodName = lcMethod + '_' + Strtran(GetWordNum(tcPath, 2, '/'), '-', '_')
				
				*this.policia(lcCustomMethodName)
				
				* Obtener los parámetros
				loParamsCollection 	= CreateObject('Collection')
				For i = 3 to GetWordCount(tcPath, '/')
					loParamsCollection.Add(GetWordNum(tcPath, i, '/'))
				EndFor
				
				If Empty(loParamsCollection.count) and !Empty(loRequest.GetUrlParam())
					loParamsCollection.Add(loRequest.GetUrlParam())
				EndIf
				
				* Verificar si existe el controlador
				If !loController.MethodExists(lcCustomMethodName)
					this.setError404()
					Return
				EndIf
				lbIsCustomMethod = .t.
			else				
				If Empty(This.oControllers.GetKey(tcPath))
					this.setError404()
					Return
				EndIf
				loController = This.oControllers.Item(This.oControllers.GetKey(tcPath))
				this.setControllerProperties(loController)
				If loController.bHandleURL
					If this.executeManualURL(loController, lcURL)
						Return
					EndIf
				EndIf
			endif
&& --> IRODG 19/01/2024
			
			If lbIsCustomMethod
				lcCalledMethod = lcCustomMethodName
			Else
				Do Case
				Case lcMethod == 'GET'
					If !Empty(loRequest.GetUrlParam())
						lcCalledMethod = "GetOne"
					Else
						lcCalledMethod = "GetAll"
					EndIf
				Case lcMethod == 'POST'
					lcCalledMethod = "Create"
				Case lcMethod == 'PUT'
					lcCalledMethod = "Update"
				Case lcMethod == 'DELETE'
					lcCalledMethod = "Delete"
				EndCase
			EndIf			
			loController.SetMethod(lcCalledMethod)
			loController.SetURL(lcURL)

			If !loController.BeforeExecute() && Método Hook BeforeExecute
				Return .f.
			EndIf

			If lbIsCustomMethod
				Local lcMacro
				lcMacro = 'loController.CallMethod("' + lcCustomMethodName + '"'
				For i=1 to loParamsCollection.count
					lcMacro = lcMacro + ',"' + loParamsCollection.Item(i) + '"'
				EndFor
				lcMacro = lcMacro + ')'
				&lcMacro
			Else
				Do Case
				Case lcMethod == 'GET' 		&& GetOne() or GetAll()
					this.HandleGetMethod(loController, loRequest.GetUrlParam())
				Case lcMethod == 'POST' 	&& Create()
					this.HandlePostMethod(loController)
				Case lcMethod == 'PUT' 		&& Update()
					this.HandlePutMethod(loController, loRequest.GetUrlParam())
				Case lcMethod == 'DELETE' 	&& Delete()
					this.HandleDeleteMethod(loController, loRequest.GetUrlParam())
				EndCase
			EndIf

			loController.AfterExecute() && Ejecutar el método Hook AfterExecute
		Endif
	Endproc

	Hidden procedure executePRGFile(tcPRGFile as String)
		Local lcCode as memo, lcResult as memo, lbIsExpr, lbAddMacros
*!*			If Type('_screen.oRequest') == 'U'
*!*				AddProperty(_screen, 'oRequest', .null.)
*!*			EndIf
*!*			If Type('_screen.oResponse') == 'U'
*!*				AddProperty(_screen, 'oResponse', .null.)
*!*			EndIf
		If Type('_screen.oInstance') == 'U'
			AddProperty(_screen, 'oInstance', .null.)
		EndIf
*!*			_screen.oRequest = this.oInstance.oRequest
*!*			_screen.oResponse = this.oInstance.oResponse
		_screen.oInstance = this.oInstance

		lbIsExpr = .F.
		lbAddMacros = .T.

		** Default settings
		this.oInstance.oResponse.SetStatusCode(200)
		this.oInstance.oResponse.SetContentType("text/html")
		this.oInstance.oResponse.SetContent(lcResult)

		lcResult = this.ParseVFPCode(FileToStr(tcPRGFile), lbIsExpr, lbAddMacros)
		this.oInstance.oResponse.SetContent(lcResult)

*!*			_screen.oRequest = .null.
*!*			_screen.oResponse = .null.
		_screen.oInstance = .null.
		
	EndProc

	Hidden procedure setControllerProperties(toController)
		If this.bIsPostAndJSon
			toController.oJson = this.oInstance.oJson
		EndIf
		
		toController.oRequest  = this.oInstance.oRequest
		toController.oResponse = this.oInstance.oResponse
		toController.oResponse.SetContentType("application/json") && we always return 'application/json'
		toController.oResponse.SetStatusCode(200) && OK
	EndProc	

	Hidden function executeManualURL(toController, tcURL)
		Local lbSuccess
		lbSuccess = .F.
		try
			Try
				toController.URLDispatch(tcURL)
				lbSuccess = .T.
			Catch to loEx									
				This.Log(LOG_ERROR, "Error " + Transform(loEx.ErrorNo) + " at line " + Transform(loEx.LineNo) + ": " + loEx.Message)
			EndTry
		Catch
		EndTry
		Return lbSuccess
	endfunc

	Hidden function getController(tcControllerName)
		* Verificar si existe el controlador
		Local i, loController
		For i=1 to this.oControllers.count
			loController = this.oControllers.Item(i)
			If Lower(loController.name) == tcControllerName
				* Setear las propiedades del controlador
				this.setControllerProperties(loController)
*!*					If this.bIsPostAndJSon
*!*						loController.oJson = this.oInstance.oJson
*!*					EndIf
*!*					
*!*					loController.oRequest  = This.oInstance.oRequest
*!*					loController.oResponse = this.oInstance.oResponse
*!*					loController.oResponse.SetContentType("application/json") && we always return 'application/json'
*!*					loController.oResponse.SetStatusCode(200) && OK
				Return loController
			EndIf
		EndFor

		Return .null.
	EndFunc

	Hidden function HandleGetMethod(toController, tcURLParam)
		If !Empty(tcURLParam) && GetOne()
			toController.GetOne(tcURLParam)
		Else && GetAll()			
			toController.GetAll(toController.oRequest.GetQueryParameter())
		EndIf
	EndFunc

	Hidden function HandlePostMethod(toController)
		Local loBody
		loBody = This.GetRequestBody()
		If !Isnull(loBody)
			This.oInstance.oResponse.SetStatusCode(201)
			toController.Create(loBody)
			If toController.oResponse.GetStatusCode() == 201 && Created
				toController.oResponse.SetLocation(Alltrim(Transform(toController.GetLastID())))
			EndIf
		Else
			this.SetError400("POST requests without a body are not supported.")
		Endif
	EndFunc

	Hidden function HandlePutMethod(toController, tcURLParam)
		If !Empty(tcURLParam)
			Local loBody
			loBody = This.GetRequestBody()
			If !Isnull(loBody)
				toController.Update(tcURLParam, loBody)
			Else
				this.SetError400("PUT requests without a body are not supported.")
			Endif
		Else
			this.SetError400("You cannot send a PUT without specifying its identifier.")
		Endif
	EndFunc

	Hidden function HandleDeleteMethod(toController, tcURLParam)
		If !Empty(tcURLParam)
			This.oInstance.oResponse.SetStatusCode(204)
			toController.Delete(tcURLParam)
		Else
			this.SetError400("You cannot send a DELETE without specifying its identifier.")
		Endif
	EndFunc

	Function GetAPIPath as String
		Return this.oInstance.cAPIPath
	EndFunc

	Hidden Function GetRequestBody As Object
		If !Isnull(This.oInstance.oJson)
			* application/json
			Return This.oInstance.oJson
		EndIf

		Local loMultipart
		loMultipart = This.oInstance.oRequest.GetMultipart()
		If loMultipart.count > 0
			* x-www-form-urlencoded
			* multipart/form-data
			Return loMultipart
		EndIf
		
		** No se admiten peticiones PUT/POST sin cuerpos
		** NOTA: esto puede cambiar.
		Return .Null.
	EndFunc

	Function EscapeCharsToJSON(tcStream) as string
		Return this.oUtility.EscapeCharsToJSON(tcStream)
	EndFunc

	Function GetPort As Integer
		Return This.oInstance.nPort
	Endfunc

	Function GetHost As String
		Return This.oInstance.cHost
	Endfunc

	Procedure ResetJsonObject
		this.bIsPostAndJSon  = .F.
		This.oInstance.oJson = .Null.
	Endproc

	Function SetResponse(toResponse As Response)
		This.oInstance.oResponse = toResponse
	Endfunc

	Function SetRequest(toRequest As Request)
		This.oInstance.oRequest = toRequest
	Endfunc

	Function SetRequestURLParam(tvValue As Variant)
		This.oInstance.oRequest.SetUrlParam(tvValue)
	Endfunc

	Procedure SetIsPostAndJSon(tbValue as Boolean)
		this.bIsPostAndJSon = tbValue
	EndProc

	procedure SetConfigFile(tcConfigFile as String) as void
		this.cConfigFile = tcConfigFile
	EndProc
	
	Procedure SetLogFile(tcLogFile as String) as VOID
		this.cLogFile = tcLogFile
	EndProc
	
	Function IsReady as Boolean
		Return this.bLoadedOk
	EndFunc

	Procedure UpdateResponseFromInstance(toResponse as Response)
		Local loInstanceResponse
		loInstanceResponse = this.oInstance.oResponse
		With toResponse
			.SetStatusCode(loInstanceResponse.GetStatusCode())
			.SetContentType(loInstanceResponse.GetContentType())
			.SetContent(loInstanceResponse.GetContent())
			.SetLocation(loInstanceResponse.GetLocation())
			.SetHeader(loInstanceResponse.GetHeader())
		EndWith
	EndProc
	
	Function GetInstanceResponse as Response
		Return this.oInstance.oResponse
	EndFunc
&& ------------------------------------------------------------- &&
&& Hidden helper functions
&& ------------------------------------------------------------- &&
	Hidden Function GetKey(tcKey)
		Local lnIdx
		lnIdx = This.oConfig.GetKey(tcKey)
		If lnIdx > 0
			Return This.oConfig.Item(lnIdx)
		Endif
		Return Space(1)
	Endfunc

	Hidden Function LoadConfig
		Local loConfig As Collection, lcContent, i, lcKey, lcValue, lcLine
		loConfig = Createobject("Collection")

		lcContent = Filetostr(This.cConfigFile)

		Local Array laLines[1]
		Alines(laLines, lcContent, 4, CRLF)

		For Each lcLine In laLines
			lcKey = Alltrim(Getwordnum(lcLine, 1, '='))
			lcValue = Alltrim(Getwordnum(lcLine, 2, '='))
			loConfig.Add(lcValue, lcKey)
		Endfor

		Return loConfig
	Endfunc

	Hidden Function Log(tnType, tcMessage)
		this.oUtility.log(tnType, tcMessage)
	Endfunc

	Hidden Procedure SetError500(tcMessage)
		tcMessage = this.EscapeCharsToJSON(tcMessage)
		With This.oInstance.oResponse
			.SetStatusCode(500)
			.SetContentType("application/json")
			.SetContent(Textmerge('{"<<this.cEstado>>": "error", "data": null, "<<this.cMensaje>>": "<<tcMessage>>"}'))
		Endwith
	EndProc
	
	Hidden Procedure SetError400(tcMessage)
		tcMessage = this.EscapeCharsToJSON(tcMessage)
		With This.oInstance.oResponse
			.SetStatusCode(400)
			.SetContentType("application/json")
			.SetContent(Textmerge('{"<<this.cEstado>>": "error", "data": null, "<<this.cMensaje>>": "<<tcMessage>>"}'))
		Endwith
	EndProc

	Hidden procedure SetError404
		With This.oInstance.oResponse
			.SetStatusCode(404)
			.SetContentType("application/json")
			.SetContent(Textmerge('{"<<this.cEstado>>": "error", "data": null, "<<this.cMensaje>>": "The requested resource could not be found"}'))
		Endwith
	endproc

	Hidden procedure policia(tcMessage)
		StrToFile(tcMessage + CRLF, this.cLogFile, 1)
	EndProc	

	Function ParseHTML(tcHTMLFile as String) as memo
		Return This.oInstance.oHelper.ParseHTML(tcHTMLFile)
	EndFunc
	
	Function ParseVFPCode(tcCode as memo, tbIsExp as Boolean, tbAddMacros as Boolean) as memo
		Try
			Local lcResult, lcExpressionPRG, lcHelpers, lcBuiltinFunc
			lcHelpers = This.oInstance.oHelper.loadScriptHelpers()
			Text To lcBuiltinFunc noshow pretext 1 textmerge
				Function GetURLHome
					Return "http://<<this.GetHost()>>:<<this.GetPort()>>/"
				EndFunc
				Function GetLang
					Return "<<Upper(this.cLang)>>"
				EndFunc
			EndText
			lcHelpers = lcHelpers + CRLF + lcBuiltinFunc
			If tbIsExp
				* Evaluar la expresión
				Text to lcExpressionPRG noshow pretext 1 textmerge
					Return Evaluate([<<tcCode>>])
					<<lcHelpers>>
				EndText
				lcResult = Transform(ExecScript(lcExpressionPRG))
			Else
				lcResult = This.oInstance.oHelper.executeScript(tcCode, lcHelpers, tbAddMacros)
			EndIf
		Catch to loEx
			Local lcWhere
			lcWhere = Iif(tbIsExp, " expression ", " script ")
			lcResult = Textmerge('<<This.oInstance.oHelper.getHTMLExceptionMessage(loEx, lcWhere)>>') && Añadimos el mensaje de la excepción
		EndTry

		Return lcResult
	EndFunc

	Function GetJsonResponse(tcEstado as string, tcData as memo, tcMessage as memo) as memo
		Return Textmerge('{"<<this.cEstado>>": "<<tcEstado>>", "data": <<Iif(Empty(tcData) OR IsNull(tcData), "null", tcData)>>, "<<this.cMensaje>>": "<<this.EscapeCharsToJSON(tcMessage)>>"}')
	EndFunc
	
	Function GetLang as string
		Return this.cLang
	EndFunc
	
	Function GetAllowedOrigins as String
		Return this.cAllowedOrigins
	EndFunc	
Enddefine