** CLASE CONTROLLERCREATOR PARA AGREGAR ROUTES Y CONTROLLERS
Define Class ControllerCreator as Custom
	oRoutes = .null.
	oControllers = .null.
		
	Procedure init
		this.oRoutes = CREATEOBJECT("Collection")
		this.oControllers = CREATEOBJECT("Collection")
	EndProc
	
	PROCEDURE addRoute(tcPath, tcDelagate)
		This.oRoutes.Add(tcDelagate, tcPath)
	ENDPROC
	
	PROCEDURE addController(tcPath, toInstance)
		toInstance.oHelper = CreateObject("ControllerHelper")
		This.oControllers.Add(toInstance, tcPath)
	ENDPROC
EndDefine