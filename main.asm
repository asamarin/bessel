COMMENT	#
    +----------------------------+
       Alejandro Samarin Perez   
    +----------------------------+
    
    Practica de Tecnologia de Computadores
    
    Este programa calcula los valores de la funcion de 
    Bessel de orden 0, en el rango especificado por el
    usuario y con el numero de valores deseado.
    
#

.386 
.model flat, stdcall    ; Modelo de memoria sin segmentar y convencion de paso de parametros stdcall
option casemap:none     

; Archivo de cabecera donde estan definidos todos los ficheros necesarios que hay 
; que importar, asi como constantes, macros y prototipos de las funciones 
; utilizadas aqui    
include .\head.asm
include .\macros.asm

; Comienzo del codigo
.code 
start: 
    invoke GetModuleHandle, NULL    ; Obtenemos el handle de nuestra ventana de dialogo
    mov hInstance, eax 
    invoke WinMain, hInstance, NULL, NULL, SW_SHOWDEFAULT ; Funcion principal
    invoke ExitProcess, eax
    invoke InitCommonControls       ; Esta linea hay que especificarla para que Windows cargue el ListView (es un CommonControl)

; FUNCION   : Calc_polynomial
; PROPOSITO : Calcular un polinomio segun la regla de Horner
; PARAMETROS:
;   ST(0) = Punto en el que evaluar el polinomio
;   EBX = Direccion del primer elemento del vector de coeficientes
;   len_vector = Longitud del vector de coeficientes que se esta calculando en este momento
; VALOR DE RETORNO: Resultado de la evaluacion del polinomio en ST(0)
Calc_polynomial proc len_vector:DWORD
    push ecx
    push esi
    xor ecx, ecx
    xor esi, esi
    mov ecx, len_vector
    shr ecx, 3   ; al = Num elementos del vector [len_vector (en bytes) / 8]
    dec ecx
    fld qword ptr [ebx]
    add esi, 8
    @bucle:
        fmul st, st(1)
        fadd qword ptr [ebx + esi]
        add esi, 8
        loop @bucle
    fstp st(1)
    pop esi
    pop ecx
    ret
Calc_polynomial endp

; FUNCION   : bessel
; PROPOSITO : Calcular la funcion de Bessel de orden 0 en un punto 
; PARAMETROS:
;   x = Punto en el que evaluar la funcion
; VALOR DE RETORNO: Resultado de la evaluacion de la funcion en ST(0)
bessel proc x:REAL4
    push ebx
    finit
    fld x       ; x
    fabs        ; abs(x)
    fst aax     ; abs(x)
    fld EIGHT   ; 8.0 | abs(x)
    fcomp aax   ; abs(x)
    FPU_STATUS  
    jbe @else   ; abs(x)
    fmul st(0), st(0)   ; x^2
    fst y       ; y
    lea ebx, FIRST_ANS1
    invoke Calc_polynomial, FIRST_LEN   ; Devuelve ans1 en st(0)
    fld y       ; y | ans1
    lea ebx, FIRST_ANS2 ; y | ans1
    invoke Calc_polynomial, FIRST_LEN   ; ans2 | ans1
    fdivp st(1), st ; ans = ans1 / ans2
    jmp @end
@else:
    fld EIGHT   ; 8.0 | abs(x)
    fdivrp st(1), st    ; z
    fst z       ; z
    fmul st, st ; z^2
    fst y       ; y = z^2
    fld NUM1    ; num1 | y
    fld aax     ; aax | num1 | y
    fsubrp st(1), st  ; xx | y
    fstp xx     ; y
    lea ebx, SECOND_ANS1    ; y 
    invoke Calc_polynomial, SECOND_LEN  ; ans1
    fld y       ; y | ans1
    lea ebx, SECOND_ANS2    ; y | ans1
    invoke Calc_polynomial, SECOND_LEN  ; ans2 | ans1
    ;-----
    fld xx      ; xx | ans2 | ans1
    fsincos     ; cos(xx) | sin(xx) | ans2 | ans1
    fmul st, st(3)  ; cos(xx) * ans1 | sin(xx) | ans2 | ans1
    ffree st(3) ; cos(xx) * ans1 | sin(xx) | ans2
    fxch st(2)  ; ans2 | sin(xx) | cos(xx) * ans1
    fmul        ; sin(xx) * ans2 | cos(xx) * ans1
    fld z       ; z | sin(xx) * ans2 | cos(xx) * ans1
    fmul        ; z * sin(xx) * ans2 | cos(xx) * ans1
    fsub        ; (cos(xx) * ans1) - (z * cos(xx) * ans2)
    ;-----
    fld aax     ; aax | (cos(xx) * ans1) - (z * cos(xx) * ans2)
    fld NUM2    ; num2 | aax | (cos(xx) * ans1) - (z * cos(xx) * ans2)
    fdivr       ; num2 / aax | (cos(xx) * ans1) - (z * cos(xx) * ans2)
    fsqrt       ; sqrt(num2/aax) | (cos(xx) * ans1) - (z * cos(xx) * ans2)
    fmul        ; ans = (sqrt(num2/aax)) * ((cos(xx) * ans1) - (z * cos(xx) * ans2))
@end:
    pop ebx
    ret
bessel endp    
    
; FUNCION   : CreateCol
; PROPOSITO : Insertar una nueva columna en el ListView
; PARAMETROS:
;   hDlg = Handle de la ventana de dialogo principal (donde esta situado el ListView)
;   nCol = Indice de la columna a insertar (0 es la primera)
;   nFormat = Constante que especifica la alineacion del texto
;   pszLabel = Puntero a cadena ASCIIZ que contiene el texto que se mostrara en la cabecera de la columna
;   nWidth = Entero que indica el ancho en pixeles que tendra la nueva columna
; VALOR DE RETORNO: Nada
CreateCol proc hDlg:HWND, nCol:DWORD, nFormat:DWORD, pszLabel:LPTSTR, nWidth:DWORD
    LOCAL lvc:LV_COLUMN
    
    .IF nCol == THIRD_COLUMN
        mov lvc.imask, LVCF_FMT or LVCF_TEXT
    .ELSE
        mov lvc.imask, LVCF_FMT or LVCF_TEXT or LVCF_WIDTH
        push nWidth
        pop lvc.lx
    .ENDIF
    push nFormat
    pop lvc.fmt
    push pszLabel
    pop lvc.pszText
    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_INSERTCOLUMN, nCol, addr lvc
    .IF nCol == THIRD_COLUMN
        invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_SETCOLUMNWIDTH, nCol, LVSCW_AUTOSIZE_USEHEADER
    .ENDIF
    ret
CreateCol endp

; FUNCION   : InsertItem
; PROPOSITO : Insertar una nueva fila en el ListView
; PARAMETROS:
;   hDlg = Handle de la ventana de dialogo principal (donde esta situado el ListView)
;   nRow = Indice de la fila en el que insertar el nuevo item (empieza en 0)
;   pszText1 = Puntero a cadena ASCIIZ que contiene el texto que se mostrara en el primer campo de la fila (N)
;   pszText2 = Puntero a cadena ASCIIZ que contiene el texto que se mostrara en el segundo campo de la fila (x)
;   pszText3 = Puntero a cadena ASCIIZ que contiene el texto que se mostrara en el tercer campo de la fila (f(x))
; VALOR DE RETORNO: Nada
InsertItem proc hDlg:HWND, nRow:DWORD, pszText1:LPTSTR, pszText2:LPTSTR, pszText3:LPTSTR
    LOCAL lvi:LV_ITEM
    ;------------------------------------
    mov lvi.imask, LVIF_TEXT
    push nRow
    pop lvi.iItem
    mov lvi.iSubItem, FIRST_COLUMN
    push pszText1
    pop lvi.pszText
    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_INSERTITEM, NULL, addr lvi
    mov lvi.iSubItem, SECOND_COLUMN
    push pszText2
    pop lvi.pszText
    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_SETITEM, NULL, addr lvi
    mov lvi.iSubItem, THIRD_COLUMN
    push pszText3
    pop lvi.pszText
    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_SETITEM, NULL, addr lvi
    ret
InsertItem endp
   
; FUNCION   : Calc_table
; PROPOSITO : Calcular y rellenar el ListView al completo, dados los parametros deseados
; PARAMETROS:
;   hDlg = Handle de la ventana de dialogo principal
; VALOR DE RETORNO: Nada
Calc_table proc hDlg:HWND
    LOCAL x:REAL4   ; Valor que recorre el rango deseado, evaluando en cada punto
    
    push ebx
    mov ebx, n_values
    finit
    fild lower_lim      ; lower_lim = x
    fstp x
@loop:
    inc curr_row        ; curr_row lleva la cuenta de las filas (iteraciones) para mostrar en el ListView
    invoke ltoa, curr_row, addr iter
    fld x
    invoke FpuFLtoA, NULL, 4, addr eval_value, SRC1_FPU or SRC2_DIMM ; x
    fstp x
    invoke bessel, x    ; bessj0(x = st(0))
    invoke FpuFLtoA, NULL, 10, addr fx, SRC1_FPU or SRC2_DIMM or STR_SCI ; f(x)
    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_GETITEMCOUNT, NULL, NULL
    invoke InsertItem, hDlg, eax, addr iter, addr eval_value, addr fx
    finit           ; Resetear la pila
    fld x           ; Cargar el ultimo valor de "x" utilizado
    fadd step_amnt  ; En el tope de la pila esta la ultima "x" usada, le sumamos el siguiente paso
    fstp x
    invoke SendDlgItemMessage, hDlg, IDC_PROGRESS, PBM_STEPIT, NULL, NULL
    cmp curr_row, ebx   ; Comprobamos si ya hemos computado todos los valores exigidos
    jl @loop       ; Si no es el caso, saltamos
    pop ebx
    ret
Calc_table endp

; FUNCION   : WinMain
; PROPOSITO : Punto de entrada de cualquier aplicacion basada en Windows
; PARAMETROS:
;   hInst = Handle de la instancia actual de la aplicacion
;   hPrevInst = Handle de la instancia previa de la aplicacion (siempre NULL)
;   CmdLine = Puntero a la cadena ASCIIZ que especifica la linea de comando, excluyendo el nombre del programa
;   CmdShow = Especifica como se vera la ventana (maximizada, minimizada, oculta, ...)
; VALOR DE RETORNO: Codigo de salida del bucle de mensajes en EAX
WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hDlg:HWND 
    ;------------------------------------
    mov   wc.cbSize,SIZEOF WNDCLASSEX 
    mov   wc.style, CS_HREDRAW or CS_VREDRAW 
    mov   wc.lpfnWndProc, OFFSET WndProc 
    mov   wc.cbClsExtra,NULL 
    mov   wc.cbWndExtra,DLGWINDOWEXTRA 
    push  hInst 
    pop   wc.hInstance 
    mov   wc.hbrBackground,COLOR_BTNFACE + 1 
    mov   wc.lpszMenuName,OFFSET MenuName 
    mov   wc.lpszClassName,OFFSET ClassName 
    invoke LoadIcon,NULL,IDI_APPLICATION 
    mov   wc.hIcon,eax 
    mov   wc.hIconSm,eax 
    invoke LoadCursor,NULL,IDC_ARROW 
    mov   wc.hCursor,eax 
    invoke RegisterClassEx, addr wc 
    invoke CreateDialogParam, hInstance, addr DlgName, NULL, NULL, NULL 
    mov   hDlg,eax 
    invoke ShowWindow, hDlg, SW_SHOWNORMAL
    Set_controls_properties
    .WHILE TRUE 
        invoke GetMessage, addr msg,NULL,0,0 
        .BREAK .IF (!eax) 
        invoke IsDialogMessage, hDlg, addr msg 
        .IF eax ==FALSE 
            invoke TranslateMessage, addr msg 
            invoke DispatchMessage, addr msg 
        .ENDIF 
    .ENDW 
    mov eax, msg.wParam 
    ret 
WinMain endp

; FUNCION   : WndProc
; PROPOSITO : Procesar los mensajes del sistema que se le pasan a la aplicacion
; PARAMETROS:
;   hDlg: Handle de la ventana de dialogo
;   uMsg = Numero que indica el mensaje en cuestion
;   wParam = Parametro extra que podrian utilizar los mensajes
;   lParam = Parametro extra que podrian utilizar los mensajes
; VALOR DE RETORNO: EAX = 0
WndProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    .IF uMsg==WM_DESTROY 
        invoke PostQuitMessage,NULL 
    .ELSEIF uMsg==WM_COMMAND 
        mov eax,wParam 
        .IF lParam==0 
            .IF ax==IDM_EXIT
                invoke DestroyWindow, hDlg
            .ENDIF 
        .ELSE 
            mov edx,wParam 
            shr edx,16 
            .IF dx==BN_CLICKED 
                .IF ax==IDC_CALC_BUTTON 
                    invoke GetDlgItemInt, hDlg, IDC_LLIM, NULL, TRUE
                    test eax, 80000000h     ; Comprobar bit de signo
                    jz @1
                    or llim_sign, 1
                @1: 
                    mov lower_lim, eax
                    invoke GetDlgItemInt, hDlg, IDC_ULIM, NULL, TRUE
                    test eax, 80000000h
                    jz @2
                    or ulim_sign, 1
                @2:
                    .IF (llim_sign == 1) && (ulim_sign == 0)
                        jmp @lim_ok
                    .ELSEIF (llim_sign == 0) && (ulim_sign == 1)
                        jmp @lim_err
                    .ENDIF
                    cmp lower_lim, eax
                    jbe @lim_ok
                @lim_err:
                    invoke MessageBox, hDlg, addr Lim_err_caption, NULL, MB_ICONERROR
                    jmp @exit
                @lim_ok:
                    mov upper_lim, eax
                    invoke GetDlgItemInt, hDlg, IDC_NUMVAL, NULL, FALSE
                    mov n_values, eax
                    invoke SendDlgItemMessage, hDlg, IDC_PROGRESS, PBM_SETRANGE32, NULL, eax
                    invoke SendDlgItemMessage, hDlg, IDC_LISTVIEW, LVM_DELETEALLITEMS, NULL, NULL
                    mov curr_row, 0
                    Calc_step_amnt hDlg
                    invoke Calc_table, hDlg
                    invoke SendDlgItemMessage, hDlg, IDC_PROGRESS, PBM_SETPOS, 0, NULL
                .ENDIF 
            .ENDIF 
        .ENDIF 
    .ELSE 
    @exit:
        invoke DefWindowProc,hDlg,uMsg,wParam,lParam 
        ret 
    .ENDIF 
    xor eax, eax 
    ret 
WndProc endp 
end start 
