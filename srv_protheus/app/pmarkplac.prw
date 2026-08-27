User Function pmarkplac()
    Local aArea := FWGetArea()

    chkfile("ML1")
    chkfile("ML2")
    chkfile("ML3")
    chkfile("ML4")
    chkfile("ML5")
    chkfile("ML6")
    FWCallApp("prj-pmarkplace")
    FWRestArea(aArea)
Return
