Define Class Response As Custom OlePublic
	Hidden nStatusCode, cContentType, cContent, cLocation, oHeader, cFileName, i

	Procedure Init
		With this
			.i = 0
			.nStatusCode  = 0
			.cContentType = ""
			.cContent 	  = ""
			.cLocation 	  = ""
			.cFileName 	  = ""
			.oHeader 	  = Createobject("TupleDictionary")
		EndWith
	Endproc

	Procedure AddHeader(toTuple As Tuple) As VOID
		If Type('toTuple') != 'O' or toTuple.name != 'Tuple'
			Return
		EndIf
		This.oHeader.Add(toTuple)
	EndProc
	
	Procedure SetStatusCode(tnStatusCode as Integer) as VOID
		If Type('tnStatusCode') != 'N' or !Between(tnStatusCode, 100, 599)
			tnStatusCode = 200
		EndIf
		this.nStatusCode = tnStatusCode
	EndProc
	
	function GetStatusCode as Integer
		If Empty(this.nStatusCode)
			Return 200
		EndIf
		Return this.nStatusCode
	endfunc
	
	Procedure SetContentType(tcContentType as String) as VOID
		If Type('tcContentType') != 'C' or Empty(tcContentType)
			tcContentType = 'text/plain'
		EndIf 
		this.cContentType = tcContentType
	EndProc
	
	Function GetContentType as String
		Return this.cContentType
	EndFunc
	
	Procedure SetContent(tcContent as String) as VOID
		If Type('tcContent') != 'C' or Empty(tcContent)
			tcContent = Space(1)
		EndIf 
		this.cContent = tcContent
	EndProc
	
	Function GetContent as String
		Return this.cContent
	EndFunc
	
	procedure SetLocation(tcLocation as String) as VOID
		Do case
		case Type('tcLocation') == 'N'
			tcLocation = Alltrim(Str(tcLocation))
		Case Type('tcLocation') != 'C'
			tcLocation = Space(1)
		EndCase

		this.cLocation = tcLocation
	EndProc
	
	Function GetLocation as String
		return this.cLocation
	EndFunc
	
	Procedure SetHeader(toHeader as TupleDictionary) as VOID
		this.oHeader = toHeader
	EndProc
	
	Function GetHeader as TupleDictionary
		Return this.oHeader
	EndFunc
	
	Function HasNextHeader as Boolean
		Return this.i < this.oHeader.count
	EndFunc
	
	Function GetNextHeader(toTuple as Tuple)
		this.i = this.i + 1
		Local loObj as Tuple
		loObj = this.oHeader.Item(this.i)
		toTuple.SetKey(loObj.GetKey())
		toTuple.SetValue(loObj.GetValue())
	endfunc
	
	Procedure SetFileName(tcFileName as String)
		If Empty(tcFileName) or Type('tcFileName') != 'C'
			Return
		EndIf
		this.cFileName = tcFileName
	EndProc
	
	Function GetFileName as String
		Return this.cFileName
	EndFunc

	procedure AddResponseHeader(tcKey as String, tcValue as String) as VOID
		Local loTuple as Tuple
		loTuple = CreateObject("Tuple")
		loTuple.SetKey(tcKey)
		loTuple.SetValue(tcValue)
		this.addHeader(loTuple)
	endproc	

Enddefine
