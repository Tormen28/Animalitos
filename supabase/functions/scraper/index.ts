// @ts-nocheck  // Desactivar temporalmente la verificación de tipos

// Importaciones de Deno
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

// Declaración de tipos para Deno
interface DenoEnv {
  env: {
    get(key: string): string | undefined;
  };
  exit(code?: number): never;
}

declare const Deno: DenoEnv;

// Configuración de Supabase
// Obtener variables de entorno con valores por defecto para desarrollo
const supabaseUrl = Deno?.env?.get('SUPABASE_URL') || '';
const supabaseKey = Deno?.env?.get('SUPABASE_SERVICE_ROLE_KEY') || '';

// Solo validar en producción
if (Deno?.env?.get('DENO_ENV') === 'production' && (!supabaseUrl || !supabaseKey)) {
  console.error('Error: Faltan variables de entorno necesarias');
  Deno.exit(1);
}
const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

// Mapa de números a animales
const NUMERO_A_ANIMAL: { [key: string]: string } = {
  '00': 'Ballena',
  '0': 'Delfín',
  '1': 'Carnero',
  '2': 'Toro',
  '3': 'Ciempiés',
  '4': 'Alacrán',
  '5': 'León',
  '6': 'Rana',
  '7': 'Perico',
  '8': 'Ratón',
  '9': 'Águila',
  '10': 'Tigre',
  '11': 'Gato',
  '12': 'Caballo',
  '13': 'Mono',
  '14': 'Paloma',
  '15': 'Zorro',
  '16': 'Oso',
  '17': 'Pavo',
  '18': 'Burro',
  '19': 'Chivo',
  '20': 'Cerdo',
  '21': 'Gallo',
  '22': 'Camello',
  '23': 'Cebra',
  '24': 'Iguana',
  25: 'Gallina',
  26: 'Vaca',
  27: 'Perro',
  28: 'Zamuro',
  29: 'Elefante',
  30: 'Caimán',
  31: 'Lapa',
  32: 'Ardilla',
  33: 'Pescado',
  34: 'Venado',
  35: 'Jirafa',
  36: 'Culebra'
};

// Tipos de datos
interface ResultadoSorteo {
  sorteo_id: string;
  numero_ganador: number;
  animalito_ganador: string;
  fecha: string;
  hora: string;
}

// Función para validar el número y animal
function validarNumeroYAnimal(numero: string | number, animal: string): { valido: boolean; mensaje?: string } {
  const numStr = String(numero);
  
  // Validar que el número sea válido
  if (numStr !== '00' && (isNaN(Number(numStr)) || Number(numStr) < 0 || Number(numStr) > 36)) {
    return { valido: false, mensaje: 'El número debe estar entre 00 y 36' };
  }
  
  // Obtener el animal esperado para el número
  const animalEsperado = NUMERO_A_ANIMAL[numStr];
  
  if (!animalEsperado) {
    return { valido: false, mensaje: `Número no válido: ${numero}` };
  }
  
  // Comparar ignorando mayúsculas/minúsculas y acentos
  const normalizar = (str: string) => 
    str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  
  if (normalizar(animalEsperado) !== normalizar(animal)) {
    return { 
      valido: false, 
      mensaje: `El animal para el número ${numStr} debe ser "${animalEsperado}"` 
    };
  }
  
  return { valido: true };
}

interface UsuarioNotificacion {
  id: string;
  nombre: string;
  email: string;
  notificaciones_activas: boolean;
  token_notificacion: string;
}

// Función principal
serve(async (req: Request) => {
  try {
    // Verificar el método de la solicitud
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Método no permitido' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    
    // Obtener datos del cuerpo de la solicitud
    const body = await req.json()
    
    // Verificar que se proporcionaron los datos necesarios
    if (!body.sorteo_id || body.numero_ganador === undefined || !body.animalito_ganador) {
      return new Response(
        JSON.stringify({ 
          success: false,
          error: 'Se requieren sorteo_id, numero_ganador y animalito_ganador' 
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }
    
    // Obtener y validar el número
    const numeroGanador = String(body.numero_ganador).trim();
    const animalitoGanador = String(body.animalito_ganador).trim();
    
    // Validar número y animal
    const validacion = validarNumeroYAnimal(numeroGanador, animalitoGanador);
    if (!validacion.valido) {
      return new Response(
        JSON.stringify({
          success: false,
          error: validacion.mensaje || 'Datos inválidos'
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }
    
    // Crear objeto de resultado con el animal normalizado
    const ahora = new Date();
    const resultado: ResultadoSorteo = {
      sorteo_id: body.sorteo_id,
      numero_ganador: numeroGanador,
      animalito_ganador: NUMERO_A_ANIMAL[numeroGanador], // Usar el nombre estandarizado
      fecha: ahora.toISOString().split('T')[0], // Formato YYYY-MM-DD
      hora: ahora.toTimeString().split(' ')[0]  // Formato HH:MM:SS
    };
    
    console.log('Registrando resultado:', resultado);
    
    // Actualizar el sorteo con el resultado
    const { data: sorteoActualizado, error: errorActualizacion } = await supabase
      .from('sorteos')
      .update({
        numero_ganador: resultado.numero_ganador,
        animalito_ganador: resultado.animalito_ganador,
        estado: 'finalizado',
        actualizado_en: new Date().toISOString()
      })
      .eq('id', resultado.sorteo_id)
      .select()
      .single();
      
    if (errorActualizacion) {
      console.error('Error al actualizar el sorteo:', errorActualizacion);
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Error al actualizar el sorteo',
          details: errorActualizacion.message 
        }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }
    
    // Actualizar el estado de las apuestas
    const { data: apuestasActualizadas, error: errorApuestas } = await supabase.rpc(
      'actualizar_estado_apuestas',
      { 
        p_sorteo_id: resultado.sorteo_id,
        p_numero_ganador: resultado.numero_ganador
      }
    );
    
    if (errorApuestas) {
      console.error('Error al actualizar apuestas:', errorApuestas);
      // Continuamos a pesar del error, ya que el sorteo ya se actualizó
    }
    
    // Enviar notificaciones
    await enviarNotificaciones(resultado);
    
    // Retornar éxito
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Resultado actualizado correctamente',
        sorteo: sorteoActualizado,
        apuestas_actualizadas: apuestasActualizadas || 0
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error: unknown) {
    console.error('Error en la función de scraping:', error);
    const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: errorMessage 
      }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    );
  }
})

// Función para enviar notificaciones push a los usuarios
async function enviarNotificaciones(resultado: ResultadoSorteo) {
  console.log('Preparando para enviar notificaciones...');
  
  try {
    // Obtener usuarios que tienen notificaciones activas
    const { data: usuarios, error: errorUsuarios } = await supabase
      .from('perfiles')
      .select('id, nombre, email, notificaciones_activas, token_notificacion')
      .eq('notificaciones_activas', true)
      .not('token_notificacion', 'is', null);
      
    if (errorUsuarios) {
      console.error('Error al obtener usuarios para notificaciones:', errorUsuarios);
      return { success: false, message: 'Error al obtener usuarios', error: errorUsuarios.message };
    }
    
    if (!usuarios || usuarios.length === 0) {
      console.log('No hay usuarios con notificaciones activas');
      return { success: true, message: 'No hay usuarios para notificar' };
    }
    
    console.log(`Enviando notificaciones a ${usuarios.length} usuarios...`);
    
    // Preparar el mensaje de notificación
    const titulo = '¡Nuevo resultado disponible!';
    const mensaje = `El número ganador es ${resultado.numero_ganador} (${resultado.animalito_ganador}) a las ${resultado.hora}`;
    
    // Enviar notificación a cada usuario
    const resultadosNotificaciones = [];
    
    for (const usuario of usuarios) {
      try {
        console.log(`Enviando notificación a ${usuario.email}...`);
        
        // Enviar notificación FCM
        const fcmResponse = await enviarNotificacionFCM(
          usuario.token_notificacion,
          titulo,
          mensaje,
          {
            tipo: 'resultado_sorteo',
            sorteo_id: resultado.sorteo_id,
            numero_ganador: resultado.numero_ganador,
            animalito_ganador: resultado.animalito_ganador,
            fecha: resultado.fecha,
            hora: resultado.hora
          }
        );
        
        // Registrar el resultado de la notificación
        if (fcmResponse) {
          resultadosNotificaciones.push({
            usuario_id: usuario.id,
            exito: fcmResponse.success,
            mensaje: fcmResponse.message,
            error: fcmResponse.error
          });
          
          console.log(`Notificación enviada a ${usuario.email}: ${fcmResponse.success ? 'Éxito' : 'Error'}`);
        } else {
          resultadosNotificaciones.push({
            usuario_id: usuario.id,
            exito: false,
            mensaje: 'Error al enviar notificación',
            error: 'Respuesta de FCM no válida'
          });
          
          console.error(`Error al enviar notificación a ${usuario.email}: Respuesta de FCM no válida`);
        }
        
      } catch (error: any) {
        const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
        console.error(`Error al enviar notificación a ${usuario.email}:`, errorMessage);
        
        resultadosNotificaciones.push({
          usuario_id: usuario.id,
          exito: false,
          error: errorMessage
        });
      }
    }
    
    // Registrar el envío de notificaciones
    const notificacionesExitosas = resultadosNotificaciones.filter(r => r.exito).length;
    const notificacionesFallidas = resultadosNotificaciones.length - notificacionesExitosas;
    
    console.log(`Notificaciones enviadas: ${notificacionesExitosas} exitosas, ${notificacionesFallidas} fallidas`);
    
    return {
      success: true,
      message: `Notificaciones enviadas: ${notificacionesExitosas} exitosas, ${notificacionesFallidas} fallidas`,
      detalles: resultadosNotificaciones
    };
    
  } catch (error: any) {
    const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
    console.error('Error en enviarNotificaciones:', errorMessage);
    
    return {
      success: false,
      message: 'Error al enviar notificaciones',
      error: errorMessage
    };
  }
}

// Función auxiliar para enviar notificaciones a través de FCM
async function enviarNotificacionFCM(token: string, titulo: string, mensaje: string, data: any = {}) {
  // Obtener la clave de FCM desde las variables de entorno
  const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') || '';
  
  if (!FCM_SERVER_KEY) {
    console.error('FCM_SERVER_KEY no está configurada');
    return { success: false, message: 'Configuración de FCM no encontrada' };
  }
  
  const url = 'https://fcm.googleapis.com/fcm/send';
  
  const payload = {
    to: token,
    notification: {
      title: titulo,
      body: mensaje,
      sound: 'default',
      badge: '1',
    },
    data: data,
    priority: 'high',
    content_available: true
  };
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    
    const responseData = await response.json();
    
    if (!response.ok) {
      console.error('Error en la respuesta de FCM:', responseData);
      return { 
        success: false, 
        message: 'Error al enviar notificación',
        error: responseData
      };
    }
    
    return { 
      success: true, 
      message: 'Notificación enviada exitosamente',
      data: responseData
    };
    
  } catch (error: any) {
    console.error('Error al enviar notificación FCM:', error);
    return { 
      success: false, 
      message: 'Error de red al enviar notificación',
      error: error?.message || 'Error desconocido'
    };
  }
}

// Función para registrar la notificación en la base de datos
async function registrarNotificacion(usuarioId: string, titulo: string, mensaje: string, data: any): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('notificaciones')
      .insert([{
        usuario_id: usuarioId,
        titulo: titulo,
        mensaje: mensaje,
        data: data,
        leida: false,
        created_at: new Date().toISOString()
      }]);
      
    if (error) {
      console.error('Error al registrar notificación en la base de datos:', error);
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Error al registrar notificación:', error);
    return false;
  }
}
