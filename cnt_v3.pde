// CNT
import oscP5.*;
import netP5.*;
import java.util.List;
import java.util.Arrays;
OscP5 oscP5;
NetAddress myRemoteLocation1;
NetAddress myRemoteLocation2;
String[] filasRegistro;
String[] fechasHechos;
String[] fechasRango;// Contiene todos los dias
String[] registroLlamadas;
List listaFechasHechos;
//int altoFila = 0;
int EDAD_MAX = 0;
int FILA_Y = 0;
// Contadores llamadas -------------------
int CONTADOR_LLAMADA = 0;
// Contadores Hechos -------------------
int CONTADOR_DIA = 0;
int CONTADOR_HECHO = 0;
int FRECUENCIA_HECHO = 120;
// -------------------------------------
// Indices (posicion columna) del archivo
static int IDX_CASO = 0;
static int IDX_EDAD = 1;
// Genero
// 0 - Mujer
// 1 - Hombre
// 2 - Transgenero
// 4 - no especificado
static int IDX_GENERO_NOMBRE = 2;
static int IDX_GENERO = 3;
static int IDX_PROVINCIA = 6;

// Dibujo -------------------------------
// Lineas
int intervaloLineas = 10;
int numLineas;
PVector[] posPrevLineas;
float[] posVelLineas;
float[] DRAW_X;
// Textos
int DRAW_TEXTO_Y = 0;
// -------------------------------------
// Variables globales para grafico
int[] G_EDAD = new int[24];
float[] MOVIMIENTOS = new float[24];
float[] DESPLAZAMIENTOS = new float[24];
boolean G_HECHO = false;
float G_HORA_LLAMADA = 0;
int G_PROVINCIA = -1;
// -------------------------------------
void settings() {
    //fullScreen();
    size(800, 450);
}
void setup() {
    frameRate(15);
    // NEt OSC ---------------------------------------------
    oscP5 = new OscP5(this, 12000);
    //myRemoteLocation1 = new NetAddress("192.168.0.30", 9997);
    //myRemoteLocation2 = new NetAddress("192.168.0.255", 9998);
    myRemoteLocation1 = new NetAddress("127.0.0.1", 12001);

    // ----------------------------------------------------
    filasRegistro = loadStrings("registro_hechos.csv");
    fechasHechos = loadStrings("fechas_hechos.txt");
    registroLlamadas = loadStrings("registro_llamadas.csv");
    listaFechasHechos = Arrays.asList(fechasHechos);
    fechasRango = loadStrings("fechas_rango.txt");
    // Busca el numero máximo
    for (int i = 0; i< filasRegistro.length; i++) {
        String[] cols = filasRegistro[i].split(",");
        if (int(cols[1])<110 && int(cols[1]) > EDAD_MAX) {
            EDAD_MAX = int(cols[1]);
        }
    }
    //altoFila = 1;//height / filas.length;
    // ----------------------------------------------------
    // grafico hechos -------------------------------------
    numLineas = 24;
    intervaloLineas = height / numLineas;
    posPrevLineas = new PVector[numLineas];
    posVelLineas = new float[numLineas];
    DRAW_X = new float[numLineas];
    for (int i = 0; i < numLineas; i++) {
        posPrevLineas[i] = new PVector(0, i * intervaloLineas);
        posVelLineas[i] = 1;
        DRAW_X[i] = 0;
        G_EDAD[i] = 999;
        MOVIMIENTOS[i] = 0;
        DESPLAZAMIENTOS[i] = 0;
    }
    background(0);
    noStroke();
}
void draw() {
    if (frameCount % FRECUENCIA_HECHO == 0) {
        String fechaActual = fechasRango[CONTADOR_DIA%fechasRango.length];

        // Ingresa solo si hay un hecho ---------------
        if (listaFechasHechos.contains(fechaActual)) {
            // Index para recorrer el registro
            int indexFilaRegistro = CONTADOR_HECHO % filasRegistro.length;
            // Fila actual del registro
            String[] fila = filasRegistro[indexFilaRegistro].split(",");
            G_PROVINCIA = int(fila[IDX_PROVINCIA]);
            G_EDAD[G_PROVINCIA%numLineas] = int(fila[IDX_EDAD]);
            // Envio pulso OSC
            sendPulso(fila);
            // Solo incrementa cuando hay un hecho
            CONTADOR_HECHO++;
        }
        // Contador dias del rango total
        CONTADOR_DIA++;
    }
    // LLAMADAS
    if (frameCount % int(random(2, 40))== 0) {
        ///
        int IDX = CONTADOR_LLAMADA % registroLlamadas.length;
        fill(255, random(5, 60));
        int salto = int(random(10, 100));
        int desplazamiento_x = int(random(-50, 50));
        textAlign(CENTER, CENTER);
        textSize(random(5, 40));
        text(registroLlamadas[IDX], width/2 + desplazamiento_x, DRAW_TEXTO_Y);

        String[] columnas = registroLlamadas[IDX].split(",");
        G_HORA_LLAMADA = int(columnas[columnas.length-1]);
        CONTADOR_LLAMADA++;
        // GRAFICO LLAMADAS
        DRAW_TEXTO_Y+=salto;
        if (DRAW_TEXTO_Y>height) {
            DRAW_TEXTO_Y = 0;
        }
        // Alarga hecho x llamada -------------
        posVelLineas[int(random(0, numLineas))] = 1 + (G_HORA_LLAMADA / 24);
    }
    if (frameCount % 2 == 0) {
        // Reduce el rango de amplitud
        for (int i = 0; i < numLineas; i++) {
            G_EDAD[i] += 1;
        }
    }
    // -------------------------------------------------------
    // GRAFICO -----------------------------------------------
    // -------------------------------------------------------
    for (int i = 0; i< numLineas; i++) {
        strokeWeight(random(0.1, 2));
        // NUM LINEA = ID PROVINCIA
        // Eje Y
        int DRAW_Y = int(i * intervaloLineas) + intervaloLineas;

        //
        float n = noise(DRAW_Y*0.001, frameCount*0.001);
        float mas = 0;//map(n,0,1,-100,100);
        stroke(255);

        // Amplitud
        MOVIMIENTOS[i] = constrain(map(G_EDAD[i], 0, EDAD_MAX, 200 + random(-5, 5), 1), 0, EDAD_MAX);

        // Desplazamiento eje Y
        DESPLAZAMIENTOS[i] = 0;
        if (G_PROVINCIA == i) {
            DESPLAZAMIENTOS[i] = map(sin(frameCount*4), -1, 1, -MOVIMIENTOS[i], MOVIMIENTOS[i]);
        }
        stroke(255);
        if (i == 17) {
            stroke(255, 0, 0);
        }
        // Dibujo
        line(posPrevLineas[i].x, posPrevLineas[i].y+mas, DRAW_X[i], DRAW_Y + DESPLAZAMIENTOS[i]+mas);

        // Almacena el punto previo de la linea
        posPrevLineas[i].set(DRAW_X[i], DRAW_Y + DESPLAZAMIENTOS[i]);

        // Suma velocidad a la posicion X
        DRAW_X[i] += posVelLineas[i];

        // Si X es mayor al ancho, volver a 0 la posicion previa
        if (DRAW_X[i] >= width) {
            DRAW_X[i] = 0;
            posPrevLineas[i].set(0, i * intervaloLineas);
        }
    }
    if (frameCount % 20 == 0) {
        noStroke();
        fill(0, 20);
        rect(0, 0, width, height);
    }
}

void sendPulso(String[] s) {
    //printArray(s);
    OscMessage myMessage = new OscMessage("/datos");

    myMessage.add(s); /* add an int to the osc message */

    /* send the message */
    oscP5.send(myMessage, myRemoteLocation1);
    //oscP5.send(myMessage, myRemoteLocation2);
}
void oscEvent(OscMessage theOscMessage) {
    /* print the address pattern and the typetag of the received OscMessage */
    print("### received an osc message.");
    print(" addrpattern: "+theOscMessage.addrPattern());
    println(" typetag: "+theOscMessage.typetag());
}
