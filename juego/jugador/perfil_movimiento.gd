class_name PerfilMovimiento
extends Resource
## Cómo se mueve el protagonista en una época.
##
## PRESENTE: lento, pesado, puede agacharse. PASADO: rápido y ágil (decisión D2).
## Cada perfil es un archivo .tres editable desde el Inspector.

@export_group("Velocidades (m/s)")
@export var velocidad_andar := 1.6
@export var velocidad_correr := 3.6
@export var velocidad_agachado := 0.9

@export_group("Respuesta")
## Lo rápido que alcanza la velocidad deseada (m/s²).
@export var aceleracion := 9.0
## Lo rápido que se detiene al soltar el control (m/s²).
@export var frenado := 12.0
## Lo rápido que el cuerpo gira hacia la dirección de avance.
@export var velocidad_giro := 9.0

@export_group("Acciones")
@export var puede_agacharse := true
