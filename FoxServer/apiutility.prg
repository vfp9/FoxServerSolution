* ================================================================================== *
* Clase APIUtility para conversiones y formatos
* ================================================================================== *
#include "FoxServer.h"
Define Class APIUtility as Custom
	oLogger = .null.
	oJson	= .null.
	oBridge = .null.
	
	Function EscapeCharsToJSON(tcStream) as string
		If Empty(tcStream)
			Return tcStream
		endif
		tcStream = Strtran(tcStream, '"','\u'+Padl(Strconv('"',15), 4, '0'))
		tcStream = Strtran(tcStream, '\','\u'+Padl(Strconv('\',15), 4, '0'))
		tcStream = Strtran(tcStream, '/','\u'+Padl(Strconv('/',15), 4, '0'))
		tcStream = Strtran(tcStream, Chr(13),'\u'+Padl(Strconv(Chr(13),15), 4, '0'))
		tcStream = Strtran(tcStream, Chr(10),'\u'+Padl(Strconv(Chr(10),15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '&','\u'+Padl(Strconv('&',15), 4, '0'))
		tcStream = Strtran(tcStream, '+','\u'+Padl(Strconv('+',15), 4, '0'))
		tcStream = Strtran(tcStream, '-','\u'+Padl(Strconv('-',15), 4, '0'))
		tcStream = Strtran(tcStream, '#','\u'+Padl(Strconv('#',15), 4, '0'))
		tcStream = Strtran(tcStream, '%','\u'+Padl(Strconv('%',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		tcStream = Strtran(tcStream, '�','\u'+Padl(Strconv('�',15), 4, '0'))
		Return tcStream
	EndFunc

	Function EscapeCharsToHTML(tcStream) as string
		If Empty(tcStream)
			Return tcStream
		endif
		tcStream = Strtran(tcStream, '�','&aacute;')
		tcStream = Strtran(tcStream, '�','&Aacute;')
		tcStream = Strtran(tcStream, '�','&aacute;')
		tcStream = Strtran(tcStream, '�','&Aacute;')
		tcStream = Strtran(tcStream, '�','&eacute;')
		tcStream = Strtran(tcStream, '�','&Eacute;')
		tcStream = Strtran(tcStream, '�','&eacute;')
		tcStream = Strtran(tcStream, '�','&Eacute;')
		tcStream = Strtran(tcStream, '�','&iacute;')
		tcStream = Strtran(tcStream, '�','&Iacute;')
		tcStream = Strtran(tcStream, '�','&iacute;')
		tcStream = Strtran(tcStream, '�','&Iacute;')
		tcStream = Strtran(tcStream, '�','&oacute;')
		tcStream = Strtran(tcStream, '�','&Oacute;')
		tcStream = Strtran(tcStream, '�','&oacute;')
		tcStream = Strtran(tcStream, '�','&Oacute;')
		tcStream = Strtran(tcStream, '�','&uacute;')
		tcStream = Strtran(tcStream, '�','&Uacute;')
		tcStream = Strtran(tcStream, '�','&uacute;')
		tcStream = Strtran(tcStream, '�','&uacute;')
		tcStream = Strtran(tcStream, '�','&uuml;')
		tcStream = Strtran(tcStream, '�','&Uuml;')
		tcStream = Strtran(tcStream, '�','&ntilde;')
		tcStream = Strtran(tcStream, '�','&Ntilde;')
		Return tcStream
	EndFunc
	
	procedure Log(tnType, tcMessage)
		If Type('this.oLogger') != 'O'
			this.oLogger = CreateObject("Logger")
		EndIf
		this.oLogger.Log(tnType, tcMessage)
	EndProc

	Procedure SetLogFile(tcLogFile)
		If Type('this.oLogger') != 'O'
			this.oLogger = CreateObject("Logger")
		EndIf
		this.oLogger.SetLogFile(tcLogFile)
	EndProc
	
	Function LoadJsonFox
		Local lcJsonFoxPath, lbLoadInstance
		lcJsonFoxPath = FullPath("JsonFox.app")

		If Type('_screen.json') == 'O' && Revisamos a ver si sigue activa.
			Local loTest, lbOk
			Try
				loTest = _Screen.json.parse('{"number": 1}')
				lbOk = (loTest.Number == 1)
			Catch
				lbLoadInstance = .t.
			Finally
				This.oJson = _Screen.json
			Endtry
		Else && Creamos nueva instancia
			lbLoadInstance = .t.
		EndIf

		If lbLoadInstance
			If File(lcJsonFoxPath)
				Try
					Do (lcJsonFoxPath)
					_Screen.json.lShowErrors = .F. && modo silencioso
					This.oJson = _Screen.json
				Catch To loEx
					This.oJson = .null.
					This.Log(LOG_ERROR, this.GetExceptionMessage(loEx))
				EndTry
			Else
				This.oJson = .null.
				This.Log(LOG_ERROR, "Error in LoadJsonFox: the library does not exist: " + lcJsonFoxPath)
			EndIf
		Endif
		Return Type('this.oJson') == 'O'
	EndFunc
	
	Function GetExceptionMessage(toException)
		Local lcException
		TEXT TO lcException NOSHOW PRETEXT 15 textmerge
ErrorNo: <<toException.errorno>>
Message: <<toException.message>>
LineNo: <<toException.lineno>>
Procedure: <<toException.procedure>>
		ENDTEXT
		Return lcException
	EndFunc

	*** Funci�n para convertir una fecha en un valor UNIX timestamp
	Function DTOUNX(tdFecha, tbUseMiliseconds)
	    LOCAL lnResult
	    lnResult = tdFecha - {^1970-01-01 00:00:00}
	    IF tbUseMiliseconds
	    	lnResult = lnResult * 1000
	    ENDIF
	    RETURN lnResult
	Endfunc

	*** Funci�n para convertir un valor UNIX timestamp en una fecha
	Function UNXTOD(tnUnixTimestamp)
		DO CASE
		CASE LEN(TRANSFORM(tnUnixTimestamp)) == 10
			RETURN {^1970-01-01 00:00:00} + tnUnixTimestamp
		CASE LEN(TRANSFORM(tnUnixTimestamp)) == 13
			RETURN {^1970-01-01 00:00:00} + tnUnixTimestamp / 1000
		ENDCASE
	Endfunc

	Function Base64URLEncode(tcInput)
		Local lcBase64, lcBase64URL

		lcBase64 = Strconv(tcInput, 13)  && Codificar a Base64

		&& Eliminar signos de igualdad al final de la cadena Base64
		Do While Right(lcBase64, 1) == "="
			lcBase64 = Left(lcBase64, Len(lcBase64) - 1)
		Enddo

		&& Realizar la conversi�n a Base64 URL
		lcBase64URL = Strtran(lcBase64, "+", "-")
		lcBase64URL = Strtran(lcBase64URL, "/", "_")

		Return lcBase64URL
	Endfunc


	Function Base64URLDecode(tcInput)
		Local lcResult
		lcResult = Strtran(tcInput, "-", "+")
		lcResult = Strtran(lcResult, "_", "/")
		lcResult = lcResult + Replicate("=", Mod(4 - Len(lcResult), 4))
		Return Strconv(lcResult, 14)
	EndFunc

	Function CreateJWT(tcPayload as String, tcSecret as string, tnDuration as integer)
		Local lcHeader, lcSigned, lcJWT, lcPayload, ;
		ldFechaActual, lnFechaActualUnx, ldFechaVence, lnFechaVenceUnx
		lcHeader  = '{"alg":"HS256","typ":"JWT"}'
		lcHeader  = this.Base64URLEncode(lcHeader)
		
		ldFechaActual 	 = Datetime()
		lnFechaActualUnx = this.DTOUNX(ldFechaActual)
		ldFechaVence 	 = ldFechaActual + tnDuration
		lnFechaVenceUnx  = this.DTOUNX(ldFechaVence)
		
		lcPayload = Textmerge('{"iat":<<lnFechaActualUnx>>,"exp":<<lnFechaVenceUnx>>,"meta":<<tcPayload>>}')
		tcPayload = this.Base64URLEncode(lcPayload)
		lcSigned  = this.ComputeHmacSha256(lcHeader + '.' + tcPayload, tcSecret)
		lcJWT 	  = lcHeader + '.' + tcPayload + '.' + lcSigned
		
		If this.VerifyHmacSha256(lcHeader + '.' + tcPayload, tcSecret, lcSigned)
			Return lcHeader + '.' + tcPayload + '.' + lcSigned
		EndIf
		Return ""
	EndFunc
	
	Function ParseJWT(tcJWT as string, tcSecret as string) as string
		If GetWordCount(tcJWT, '.') != 3
			This.Log(LOG_ERROR, "Error in ParseJWT: JWT token is not in the correct format.")
			Return ""
		EndIf
		If Empty(tcSecret)
			This.Log(LOG_ERROR, "Error in ParseJWT: Missing encryption key.")
			Return ""
		EndIf

		Local lcHeader, lcPayload, lcSigned
		lcHeader	= GetWordNum(tcJWT, 1, '.')
		lcPayload	= GetWordNum(tcJWT, 2, '.')
		lcSigned	= GetWordNum(tcJWT, 3, '.')
		
		If !this.VerifyHmacSha256(lcHeader + '.' + lcPayload, tcSecret, lcSigned)
			This.Log(LOG_ERROR, "ParseJWT Error: Could not verify JWT encryption, key may not be correct.")
			Return ""
		EndIf
		Return this.Base64URLDecode(GetWordNum(tcJWT, 2, '.')) && Return the Payload
	EndFunc

	Function VerifyHmacSha256(tcMessage, tcSecret, tcSigned) as Boolean
		If !File(FullPath("FSUtility.dll"))
			This.Log(LOG_ERROR, "Error in ComputeHmacSha256: the library does not exist " + FullPath("FSUtility.dll"))
			Return
		EndIf
		If Type('this.oBridge') != 'O'
			Do wwDotNetBridge		
			this.oBridge = CreateObject("wwDotNetBridge","V4")
		EndIf
		this.oBridge.LoadAssembly("FSUtility.dll")

		Return this.oBridge.InvokeStaticMethod("FSUtility.Utilities", "VerifyHmacSha256", tcMessage, tcSecret, tcSigned)
	EndFunc

	Function ComputeHmacSha256(tcMessage, tcSecret)
		If !File(FullPath("FSUtility.dll"))
			This.Log(LOG_ERROR, "Error in ComputeHmacSha256: the library does not exist " + FullPath("FSUtility.dll"))
			Return
		EndIf
		If Type('this.oBridge') != 'O'
			Do wwDotNetBridge		
			this.oBridge = CreateObject("wwDotNetBridge","V4")
		EndIf
		this.oBridge.LoadAssembly("FSUtility.dll")

		Return this.oBridge.InvokeStaticMethod("FSUtility.Utilities", "ComputeHmacSha256", tcMessage, tcSecret)
	EndFunc
		
EndDefine