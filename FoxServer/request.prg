Define Class Request As Custom OlePublic
	Hidden cMethod, oHeader, oQueryParameter, oMultipart, cBody, urlParam

	Procedure Init
		With this
			.cMethod = ""
			.oHeader = Createobject("TupleDictionary")
			.oQueryParameter = Createobject("TupleDictionary")
			.oMultipart = Createobject("TupleDictionary")
			.cBody = ""
			.urlParam = ""
		EndWith
	Endproc

	Procedure AddHeader(toTuple As Tuple)
		This.oHeader.Add(toTuple)
	Endproc

	Procedure AddQueryParameter(toTuple As Tuple)
		This.oQueryParameter.Add(toTuple)
	Endproc

	Procedure AddMultipart(toTuple As Tuple)
		This.oMultipart.Add(toTuple)
	EndProc
	
	Procedure SetMethod(tcMethod as String) as VOID
		If Type('tcMethod') != 'C' or !InList(tcMethod, "GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS")
			tcMethod = "GET"
		EndIf
		this.cMethod = tcMethod
	EndProc
	
	Function GetMethod as String
		Return Iif(Empty(this.cMethod), "GET", this.cMethod)
	EndFunc
	
	Procedure SetHeader(toHeader as TupleDictionary)
		this.oHeader = toHeader
	EndProc
	
	Function GetHeader as TupleDictionary
		Return this.oHeader
	EndFunc
	
	Procedure SetQueryParameter(toQueryParameter as TupleDictionary)
		this.oQueryParameter = toQueryParameter
	EndProc
	
	Function GetQueryParameter as TupleDictionary
		Return this.oQueryParameter
	EndFunc

	Procedure SetMultipart(toMultipart as TupleDictionary)
		this.oMultipart = toMultipart
	EndProc
	
	Function GetMultipart as TupleDictionary
		Return this.oMultipart
	EndFunc
	
	Procedure SetBody(tcBody as string) as VOID
		If Type('tcBody') != 'C'
			tcBody = Space(1)
		EndIf
		this.cBody = tcBody
	EndProc 
	
	Function GetBody as String
		Return this.cBody
	EndFunc
	
	Procedure SetUrlParam(tvValue as Variant)
		this.urlParam = tvValue
	EndProc
	
	Function GetUrlParam as String
		Return this.urlParam
	EndFunc
	
	Function HeaderExists(tcKey as String) as Boolean
		Return this.TupleDictionaryExists(this.oHeader, tcKey)
	EndFunc
	
	Function QueryParamExists(tcKey as String) as Boolean
		Return this.TupleDictionaryExists(this.oQueryParameter, tcKey)
	EndFunc

	Function MultiPartExists(tcKey as String) as Boolean
		Return this.TupleDictionaryExists(this.oMultipart, tcKey)
	EndFunc

	Function HeaderGet(tcKey as String, tvDefault as Variant) as Variant
		Return this.TupleDictionaryGet(this.oHeader, tcKey, tvDefault)
	EndFunc
	
	Function QueryParamGet(tcKey as String, tvDefault as Variant) as Variant
		Return this.TupleDictionaryGet(this.oQueryParameter, tcKey, tvDefault)
	EndFunc

	Function MultiPartGet(tcKey as String, tvDefault as Variant) as Variant
		Return this.TupleDictionaryGet(this.oMultipart, tcKey, tvDefault)
	EndFunc
	
	Hidden function TupleDictionaryExists(toTupleDictionary as TupleDictionary, tcKey as String) as Boolean
		If Type('toTupleDictionary') != 'O'
			Return .f.
		EndIf
		
		Local i, loPair
		For i=1 to toTupleDictionary.count
			loPair = toTupleDictionary.get(i)
			If loPair.GetKey() == tcKey
				Return .t.
			EndIf
		EndFor
		Return .f.
	EndFunc

	Hidden function TupleDictionaryGet(toTupleDictionary as TupleDictionary, tcKey as String, tvDefault as Variant) as Variant
		If Type('toTupleDictionary') != 'O'
			Return tvDefault
		EndIf
		
		Local i, loPair
		For i=1 to toTupleDictionary.count
			loPair = toTupleDictionary.get(i)
			If loPair.GetKey() == tcKey
				Return loPair.GetValue()
			EndIf
		EndFor
		Return tvDefault
	EndFunc
Enddefine
