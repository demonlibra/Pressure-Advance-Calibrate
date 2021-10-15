;-----------------------------------------------------------------------
;===============================Параметры===============================
;-----------------------------------------------------------------------

var temperature_hotend=220    ; Указать температуру HotEnd`а, C
var temperature_hotbed=60     ; Указать температуру стола, C

var start_point=30            ; Указать начальную точку первой тестовой линии (X=Y), мм
var step=5                    ; Указать шаг между тестовыми линиями, мм
var length=100                ; Указать длину тестовых линий, мм
var square_offset=5           ; Указать смещение квадрата вокруг тестовых линий (для прочистки сопла), мм

var nozzle_diameter=0.4       ; Указать диаметр сопла, мм
var layer_height=0.2          ; Указать высоту слоя, мм
var filament_diameter=1.75    ; Указать диаметр прутка, мм
var extrusion_multiplier=1.15 ; Указать коэффициент экструзии

var retract_length=0.5        ; Указать длину ретракта, мм
var retract_speed=30          ; Указать скорость ретракта, мм/сек

var babystepping=0.00         ; Указать BabyStepping (минус уменьшает зазор), мм

var pa_start=0.010            ; Указать начальный коэффициент Pressure Advance
var pa_step=0.005             ; Указать шаг изменения коэффициента Pressure Advance
var pa_number=10              ; Указать количество тестовых линий

var slow_speed=30             ; Указать медленную скорость печати тестовых линий, мм/сек
var fast_speed=100            ; Указать быструю скорость печати тестовых линий, мм/сек
var travel_speed=150          ; Указать скорость холостых перемещений, мм/сек

;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
;=======================================================================
;=======================================================================

M300 P500                                                               ; Звуковой сигнал
T0                                                                      ; Выбор инструмента 0
M207 F{var.retract_speed*60} S{var.retract_length} Z0                   ; Задание параметров ретрактов
M572 D0 S0                                                              ; Сброс коэффициента Pressure Advance
M83                                                                     ; Выбор относительных координат оси экструдера

M104 S{var.temperature_hotend-80}                                       ; Предварительный нагрев сопла
M190 S{var.temperature_hotbed}                                          ; Нагрев стола с ожиданием достижения температуры

G28                                                                     ; Калибровка всех осей
M290 R0 S{var.babystepping}                                             ; Задание BabyStepping 

; ----------------------------------------------------------------------   

M300 P500                                                               ; Звуковой сигнал
G90                                                                     ; Выбор абсолютных перемещений
G1 X{var.start_point-var.square_offset} Y{var.start_point-var.square_offset} Z10 F{var.travel_speed*60}
G1 Z0 F{var.slow_speed*60}                                              ; Упираем сопло в стол чтобы пластик не вытекал
M109 S{var.temperature_hotend}                                          ; Нагрев сопла

; Расчёт длин перемещения и выдавливаемого филамента квадрата прочистки сопла
var move_lengthX=var.length+var.square_offset*2                         ; Длина квадрата вдоль X
var filament_lengthX=(var.nozzle_diameter*var.layer_height*var.move_lengthX)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier
var move_lengthY=var.pa_number*var.step+var.square_offset*2             ; Длина квадрата вдоль Y
var filament_lengthY=(var.nozzle_diameter*var.layer_height*var.move_lengthY)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier


; Прочистка сопла (квадрат вокруг тестовых линий)
M300 P500                                                               ; Звуковой сигнал
G90                                                                     ; Выбор абсолютных перемещений
G1 Z{var.layer_height}                                                  ; Перемещение на высоту слоя
G91                                                                     ; Выбор относительных перемещений
G1 X{var.move_lengthX} E{var.filament_lengthX} F{var.slow_speed*60}     ; Печать линии X+
G1 Y{var.move_lengthY} E{var.filament_lengthY} F{var.slow_speed*60}     ; Печать линии Y+
G1 X{-var.move_lengthX} E{var.filament_lengthX} F{var.slow_speed*60}    ; Печать линии X-
G1 Y{-var.move_lengthY} E{var.filament_lengthY} F{var.slow_speed*60}    ; Печать линии Y-
G10                                                                     ; Ретракт
G90                                                                     ; Выбор абсолютных перемещений
G1 Z1                                                                   ; Переместить сопло от стола

; Расчёт длины выдавливаемого  филамента
var filament_length=(var.nozzle_diameter*var.layer_height*var.length)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier
echo "Одна линия "^(var.nozzle_diameter*var.layer_height*var.length)^" куб.мм филамента, длиной "^var.filament_length^" мм"

; ----------------------------------------------------------------------   

;Печать линий тестирования Pressure Advance
var counter=0
while var.counter<=var.pa_number
   M572 D0 S{var.pa_start+var.pa_step*var.counter} ; Set extruder pressure advance
   G90                                                                  ; Выбор абсолютных перемещений
   G1 X{var.start_point} Y{var.start_point+var.step*var.counter} F{var.travel_speed*60}
                                                                        ; Печать тестовой линии
   G1 Z{var.layer_height}                                               ; Переместить на высоту слоя
   G11                                                                  ; Возврат пластика после ретракта
   G91                                                                  ; Выбор относительных перемещений
   G1 X{var.length/4} E{var.filament_length/4} F{var.slow_speed*60}     ; Печать линии медленно
   G1 X{var.length/2} E{var.filament_length/2} F{var.fast_speed*60}     ; Печать линии быстро
   G1 X{var.length/4} E{var.filament_length/4} F{var.slow_speed*60}     ; Печать линии медленно
   G10                                                                  ; Ретракт
   G1 Z1                                                                ; Переместить сопло от стола
   echo "Линия "^var.counter^" с коэффициентом Pressure Advance = "^(var.pa_start+var.pa_step*var.counter)
                                                                        ; Вывод сообщения в консоль коэффициента Pressure Advance
   set var.counter=var.counter+1                                        ; Увеличение счётчика

   
; ----------------------------------------------------------------------   
; Завершающий код
M104 S0                                                                 ; Выключить нагреватель HotEnd`а
M140 S0                                                                 ; Выключить нагреватель стола
M300 P1000                                                              ; Звуковой сигнал
M107                                                                    ; Выключить вентилятор обдува модели
G10                                                                     ; Ретракт
G90                                                                     ; Выбор абсолютных перемещений
G1 X{var.start_point} Y{var.start_point} Z150 F{var.travel_speed*60}    ; Перестить стол и голову в сторону
M290 R0 S0                                                              ; Сбросить значение BabyStepping
M400                                                                    ; Дождаться завершения перемещения
M18                                                                     ; Выключить питание моторов
