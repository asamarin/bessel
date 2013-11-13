; Fichero de cabecera que incluye definiciones de constantes, 
; variables y funciones utilizadas en el programa

include \masm32\include\windows.inc 
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 
include \masm32\include\comctl32.inc
include \masm32\m32lib\masm32.inc   ; Para la funcion ltoa()
include \masm32\fpulib\fpu.inc      ; Para la funcion FPUFlToA
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\comctl32.lib
includelib \masm32\m32lib\masm32.lib
includelib \masm32\fpulib\fpu.lib

WinMain         proto :DWORD, :DWORD, :DWORD, :DWORD 
Calc_polynomial proto :DWORD
bessel          proto :REAL4
CreateCol       proto :HWND, :DWORD, :DWORD, :LPTSTR, :DWORD
InsertItem      proto :HWND, :DWORD, :LPTSTR, :LPTSTR, :LPTSTR
Calc_table      proto :HWND
WndProc         proto :HWND, :UINT, :WPARAM, :LPARAM 

.data 
ClassName       db "DLGCLASS",0 
MenuName        db "Menu",0 
DlgName         db "Dialog",0 
Column1_Caption db "Iter",0
Column2_Caption db "x",0
Column3_Caption db "f(x)",0
Lim_err_caption db "Error en los limites: el limite inferior no puede ser mayor que el superior",0
curr_row        DWORD   0   ; Contador de iteracion actual

.data? 
hInstance   HINSTANCE   ?   ; Handle de la ventana de dialogo principal
iter        db  6   dup(?)  ; Cadena ASCIIZ donde se escribira la "N" actual (primera columna)
eval_value  db  12  dup(?)  ; "   "      "    "      "      "   " "x" actual (segunda columna)
fx          db  32  dup(?)  ; "   "      "    "      "      "  el valor f(x) actual (tercera y ultima columna)
llim_sign   db  1   dup(?)  ; Byte para comprobar errores de rangos
ulim_sign   db  1   dup(?)
n_values    DWORD   ?       ; Numero de valores deseado
upper_lim   DWORD   ?       ; Limite superior especificado
lower_lim   DWORD   ?       ; Limite inferior especificado
step_amnt   REAL4   ?       ; (Lim_sup - Lim_inf / n_valores)
aax         REAL4   ?       ; Variables de la funcion bessel()
z           REAL4   ?  
xx          REAL8   ?
y           REAL8   ?

.const 
FIRST_COLUMN    equ 0
SECOND_COLUMN   equ 1
THIRD_COLUMN    equ 2
SPINBOX_LLIMIT  equ -30
SPINBOX_ULIMIT  equ 30
;--------------------------
; Identificadores de controles graficos
;--------------------------
IDC_LISTVIEW    equ 1000
IDC_ULIM        equ 1001
IDC_SPIN1       equ 1002
IDC_LLIM        equ 1003 
IDC_SPIN2       equ 1004
IDC_GROUP       equ 1005
IDC_STATIC1     equ 1006
IDC_STATIC2     equ 1007
IDC_STATIC3     equ 1008
IDC_NUMVAL      equ 1009
IDC_CALC_BUTTON equ 1010
IDC_PROGRESS    equ 1011
;--------------------------
; Identificador del menu
;--------------------------
IDM_EXIT        equ 2000

; Vectores de coeficientes:       An       ,     An-1     ,       An-2    ,   ·  ·  ·  ·  ·  ·  ·  ·  ·   ,       A0        
FIRST_ANS1      REAL8   -184.9052456, 77392.33017, -11214424.18, 651619640.7, -13362590354.0, 57568490574.0
FIRST_ANS2      REAL8   1.0, 267.8532712, 59272.64853, 9494680.718, 1029532985.0, 57568490441.0
FIRST_LEN       equ     $-FIRST_ANS2
SECOND_ANS1     REAL8   0.2093887211e-6, -0.2073370639e-5, 0.2734510407e-4, -0.1098628627e-2, 1.0
SECOND_ANS2     REAL8   -0.934935152e-7, 0.7621095161e-6, -0.6911147651e-5, 0.1430488765e-3, -0.1562499995e-1
SECOND_LEN      equ     $-SECOND_ANS2
NUM1            REAL8   0.785398164
NUM2            REAL8   0.636619772
EIGHT           REAL8   8.0
