"""Planos cinematográficos del Patio Central.

- «Mirada» (referencia: panel superior izquierdo de Materiales/94c42e3c-....png): Elías, junto a la
  barandilla, alza la vista hacia los pisos de celdas que se pierden en la niebla. Arriba, en un
  puente, El Uniforme lo observa. Es el plano principal.
- «Pasarela» (referencia: Materiales/1b065952-....png): cámara detrás del hombro, a lo largo de la
  pasarela.

Monta assets/escenas/<plano>.blend ENLAZANDO el escenario y los personajes (los personajes con
«library override» para poder posarlos aquí) y renderiza en assets/renders/.

Uso:
    blender --background --factory-startup --python assets/scripts/plano_patio.py [-- --borrador] [--pasarela]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import comun as C  # noqa: E402
import humano as H  # noqa: E402
from kit_prision import PLANTA  # noqa: E402

PLANTA_CAMARA = 7
Z_SUELO = PLANTA_CAMARA * PLANTA         # suelo de la pasarela del plano (22,4 m)
X_MURO = -13.0                            # plano del muro oeste


def enlazar_coleccion(ruta, nombre):
    with bpy.data.libraries.load(str(ruta), link=True, relative=True) as (origen, destino):
        destino.collections = [nombre]
    return destino.collections[0]


def personaje(nombre_archivo, nombre_coleccion, escena):
    """Enlaza un personaje y crea un override editable (para posarlo en este plano)."""
    col = enlazar_coleccion(C.RAIZ / "personajes" / f"{nombre_archivo}.blend", nombre_coleccion)
    try:
        local = col.override_hierarchy_create(escena, bpy.context.view_layer, do_fully_editable=True)
    except Exception as error:  # noqa: BLE001
        print("Aviso override:", error)
        escena.collection.children.link(col)
        local = col
    if local.name not in escena.collection.children:
        try:
            escena.collection.children.link(local)
        except RuntimeError:
            pass
    arm = next(o for o in local.all_objects if o.type == "ARMATURE")
    return local, arm


def luz(nombre, tipo, energia, color, posicion, apuntar_a=None, **props):
    datos = bpy.data.lights.new(nombre, tipo)
    datos.energy = energia
    datos.color = color
    for clave, valor in props.items():
        setattr(datos, clave, valor)
    obj = bpy.data.objects.new(nombre, datos)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = posicion
    if apuntar_a is not None:
        obj.rotation_euler = (Vector(apuntar_a) - Vector(posicion)).to_track_quat("-Z", "Y").to_euler()
    return obj


def fluorescente(nombre, posicion, energia=55.0):
    """Luminaria del kit (enlazada) + luz de área que ilumina de verdad."""
    malla = bpy.data.meshes.get("M_Kit_Fluorescente")
    if malla is None:
        with bpy.data.libraries.load(str(C.RAIZ / "kit" / "kit_prision.blend"), link=True,
                                     relative=True) as (origen, destino):
            destino.meshes = ["M_Kit_Fluorescente"]
        malla = destino.meshes[0]
    obj = bpy.data.objects.new(nombre, malla)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = posicion
    obj.rotation_euler = (0, 0, math.pi / 2)
    luz(f"{nombre}_Luz", "AREA", energia, (0.8, 0.94, 1.0), Vector(posicion) - Vector((0, 0, 0.14)),
        apuntar_a=Vector(posicion) - Vector((0, 0, 3)), shape="RECTANGLE", size=0.25, size_y=1.25)


def camara(nombre, posicion, objetivo, lente):
    datos = bpy.data.cameras.new(nombre)
    datos.lens = lente
    datos.sensor_width = 36
    datos.clip_end = 400
    cam = bpy.data.objects.new(nombre, datos)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = posicion
    cam.rotation_euler = (Vector(objetivo) - Vector(posicion)).to_track_quat("-Z", "Y").to_euler()
    return cam


def mirar(angulo_grados):
    """Vector hacia donde mira un personaje girado ese ángulo (en reposo miran a -Y)."""
    a = math.radians(angulo_grados)
    return Vector((math.sin(a), -math.cos(a), 0.0))


def posar_elias(arm, posicion, angulo, mirar_arriba=0.7):
    arm.location = posicion
    arm.rotation_euler = (0, 0, math.radians(angulo))
    bpy.context.view_layer.update()
    f = mirar(angulo)
    lado = Vector((0, 0, 1)).cross(f)               # hacia su izquierda
    H.apuntar(arm, "columna", Vector((0, 0, 1)) + f * 0.04)
    H.apuntar(arm, "pecho", Vector((0, 0, 1)) - f * 0.05)
    H.apuntar(arm, "cuello", Vector((0, 0, 1)) - f * 0.35 * mirar_arriba)
    H.apuntar(arm, "cabeza", Vector((0, 0, 1)) - f * mirar_arriba - lado * 0.12)
    # Brazos caídos, algo separados, codos algo doblados.
    H.apuntar(arm, "brazo.L", Vector((0, 0, -1)) + lado * 0.2 + f * 0.05)
    H.apuntar(arm, "antebrazo.L", Vector((0, 0, -1)) + lado * 0.1 + f * 0.35)
    H.apuntar(arm, "mano.L", Vector((0, 0, -1)) + lado * 0.1 + f * 0.3)
    H.apuntar(arm, "brazo.R", Vector((0, 0, -1)) - lado * 0.25 + f * 0.15)
    H.apuntar(arm, "antebrazo.R", Vector((0, 0, -1)) - lado * 0.15 + f * 0.6)
    H.apuntar(arm, "mano.R", Vector((0, 0, -1)) - lado * 0.1 + f * 0.6)
    H.apuntar(arm, "muslo.L", Vector((0, 0, -1)) + f * 0.12 + lado * 0.05)
    H.apuntar(arm, "pierna.L", Vector((0, 0, -1)) + lado * 0.04)
    H.apuntar(arm, "muslo.R", Vector((0, 0, -1)) - f * 0.06 - lado * 0.05)
    H.apuntar(arm, "pierna.R", Vector((0, 0, -1)) - f * 0.15 - lado * 0.04)


def posar_uniforme(arm, posicion, angulo):
    arm.location = posicion
    arm.rotation_euler = (0, 0, math.radians(angulo))
    bpy.context.view_layer.update()
    f = mirar(angulo)
    H.apuntar(arm, "cabeza", Vector((0, 0, 1)) + f * 0.35 + Vector((0, 0, -0.5)))


def crear_plano(borrador=False, pasarela=False):
    escena = C.reiniciar()
    patio = enlazar_coleccion(C.RAIZ / "escenarios" / "patio_central.blend", "Patio_Central")
    escena.collection.children.link(patio)
    with bpy.data.libraries.load(str(C.RAIZ / "escenarios" / "patio_central.blend"), link=True,
                                 relative=True) as (origen, destino):
        destino.worlds = ["Mundo_Patio"]
    escena.world = destino.worlds[0]

    _, arm_elias = personaje("elias_preso", "Elias_Preso", escena)
    _, arm_uniforme = personaje("el_uniforme", "El_Uniforme", escena)

    techo_pasarela = Z_SUELO + PLANTA - 0.27
    if pasarela:
        # Plano «Pasarela»: Elías avanza; El Uniforme espera en el puente de la planta 8.
        posar_elias(arm_elias, (X_MURO + 0.55, 12.3, Z_SUELO), 184, mirar_arriba=0.1)
        posar_uniforme(arm_uniforme, (-3.5, 24.0, 8 * PLANTA), -28)
        cam = camara("Camara_Pasarela", (X_MURO + 1.15, 10.4, Z_SUELO + 1.58),
                     (-6.0, 30.0, Z_SUELO + 4.0), 24)
        luz("Contra_Uniforme", "SPOT", 900.0, (0.75, 0.88, 1.0), (-2.0, 30.0, 8 * PLANTA + 6.5),
            apuntar_a=(-3.5, 24.0, 8 * PLANTA + 1.5), spot_size=math.radians(28), spot_blend=0.6)
        fluorescente("Fluorescente_A", (X_MURO + 0.75, 15.2, techo_pasarela), 70.0)
        fluorescente("Fluorescente_B", (X_MURO + 0.75, 9.6, techo_pasarela), 45.0)
        nombre_render = "plano_patio_pasarela"
    else:
        # Plano «Mirada»: contrapicado desde la barandilla hacia los pisos superiores.
        posar_elias(arm_elias, (X_MURO + 1.3, 12.0, Z_SUELO), 153)
        pos_u = Vector((-2.0, 20.0, 10 * PLANTA))
        posar_uniforme(arm_uniforme, pos_u, -30)
        cam = camara("Camara_Mirada", (X_MURO + 2.3, 9.4, Z_SUELO + 0.9),
                     (-4.0, 40.0, Z_SUELO + 18.6), 20)
        # Silueta: solo un contraluz suave desde detrás (sin iluminar la niebla de delante).
        luz("Contra_Uniforme", "SPOT", 350.0, (0.75, 0.88, 1.0), pos_u + Vector((0.5, 4.0, 3.5)),
            apuntar_a=pos_u + Vector((0, 0, 1.6)), spot_size=math.radians(18), spot_blend=0.5)
        fluorescente("Fluorescente_A", (X_MURO + 0.75, 13.6, techo_pasarela), 60.0)
        luz("Celda_Calida", "POINT", 25.0, (1.0, 0.72, 0.45), (X_MURO - 1.0, 11.8, Z_SUELO + 2.2),
            shadow_soft_size=0.3)
        luz("Relleno_Elias", "AREA", 40.0, (0.65, 0.78, 0.95), (X_MURO + 4.0, 15.0, Z_SUELO + 4.0),
            apuntar_a=(X_MURO + 1.3, 12.0, Z_SUELO + 1.4), size=3.0)
        nombre_render = "plano_patio_central"
    escena.camera = cam

    if borrador:
        C.configurar_render(escena, 640, 360, muestras=12, exposicion=0.9)
    else:
        C.configurar_render(escena, 1672, 941, muestras=48, exposicion=0.9)
    C.guardar_blend(C.RAIZ / "escenas" / f"{nombre_render}.blend")
    sufijo = "_borrador" if borrador else ""
    C.renderizar(escena, C.RAIZ / "renders" / f"{nombre_render}{sufijo}.png")


if __name__ == "__main__":
    args = C.argumentos()
    crear_plano(borrador="--borrador" in args, pasarela="--pasarela" in args)
