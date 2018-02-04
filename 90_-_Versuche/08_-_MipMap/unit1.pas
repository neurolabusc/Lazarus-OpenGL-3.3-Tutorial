unit Unit1;
{$include ..\..\units\opts.inc}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, Menus,
{$IFDEF COREGL}
glcorearb,
{$ELSE}
dglOpenGL,
{$ENDIF}
  oglContext, oglShader, oglMatrix, oglTextur;

type

  { TForm1 }

  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    ogc: TContext;
    Shader: TShader; // Shader Klasse
    procedure CreateScene;
    procedure InitScene;
    procedure ogcDrawScene(Sender: TObject);
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

//image image.png

(*
*)

//lineal

const
  Quad: array[0..5] of TVector3f =
    ((-1.0, -1.0, 0.0), (1.0, 1.0, 0.0), (-1.0, 1.0, 0.0),
    (-1.0, -1.0, 0.0), (1.0, -1.0, 0.0), (1.0, 1.0, 0.0));

  TextureVertex: array[0..5] of TVector2f =
    ((0.0, 0.0), (1.0, 1.0), (0.0, 1.0),
    (0.0, 0.0), (1.0, 0.0), (1.0, 1.0));

type
  TVB = record
    VAO,
    VBOVertex, VBOTex: GLuint;
  end;

(*
*)
var
  //  RotMatrix, ScaleMatrix, prodMatrix: TMatrix;   // Matrixen von der Klasse aus oglMatrix.
  FrustumMatrix,
  WorldMatrix,
  Matrix: TMatrix;
  Matrix_ID: GLint;                              // ID für Matrix.

  VBTriangle: TVB;

  Textur: array[0..1] of TTexturBuffer;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  //remove+
  Width := 340;
  Height := 240;
  //remove-
  ogc := TContext.Create(Self);
  ogc.OnPaint := @ogcDrawScene;

  CreateScene;
  InitScene;
  Timer1.Enabled := True;
end;

(*
*)
//code+
procedure TForm1.CreateScene;
begin
  Shader := TShader.Create([FileToStr('Vertexshader.glsl'), FileToStr('Fragmentshader.glsl')]);
  with Shader do begin
    UseProgram;
    Matrix_ID := UniformLocation('mat');
    glUniform1i(UniformLocation('Sampler'), 0);
  end;
  Matrix := TMatrix.Create;

  FrustumMatrix := TMatrix.Create;
  FrustumMatrix.Perspective(45, 1.0, 2.5, 1000.0); // Alternativ

  WorldMatrix := TMatrix.Create;
  WorldMatrix.Translate(0, 0, -200.0); // Die Scene in den sichtbaren Bereich verschieben.
  WorldMatrix.Scale(5.0);              // Und der Grösse anpassen.

  WorldMatrix.RotateA(1.5);  // Drehe um Y-Achse
  WorldMatrix.RotateC(pi);  // Drehe um Y-Achse

  //code-

  glGenVertexArrays(1, @VBTriangle.VAO);

  glGenBuffers(1, @VBTriangle.VBOVertex);
  glGenBuffers(1, @VBTriangle.VBOTex);
end;

(*
Texturen laden
*)
//code+
procedure TForm1.InitScene;
begin
  // ------------ Texture laden --------------

  Textur[0] := TTexturBuffer.Create;
  with Textur[0] do begin
    IsMipMap := False;
    TexParameter.Add(GL_TEXTURE_MIN_FILTER, GL_NEAREST);


    LoadTextures('mauer.xpm');
  end;

  Textur[1] := TTexturBuffer.Create;
  with Textur[1] do begin
    TexParameter.Add( GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

    LoadTextures('mauer.xpm');
  end;

  glClearColor(0.6, 0.6, 0.4, 1.0); // Hintergrundfarbe

  // Daten für Dreieck
  glBindVertexArray(VBTriangle.VAO);
  glBindBuffer(GL_ARRAY_BUFFER, VBTriangle.VBOVertex);
  glBufferData(GL_ARRAY_BUFFER, sizeof(Quad), @Quad, GL_STATIC_DRAW);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, nil);

  glBindBuffer(GL_ARRAY_BUFFER, VBTriangle.VBOTex);
  glBufferData(GL_ARRAY_BUFFER, sizeof(TextureVertex), @TextureVertex, GL_STATIC_DRAW);
  glEnableVertexAttribArray(10);
  glVertexAttribPointer(10, 2, GL_FLOAT, GL_FALSE, 0, nil);
end;
//code-

(*
*)
//code+
procedure TForm1.ogcDrawScene(Sender: TObject);
var
  x, y: integer;
const
  d = 2.0;
  s = 8;
begin
  Matrix := TMatrix.Create;
  glClear(GL_COLOR_BUFFER_BIT);

  Textur[0].ActiveAndBind();
  //code-

  Shader.UseProgram;

  glBindVertexArray(VBTriangle.VAO);
  for x := -s to s do begin
    for y := -s * 10 to s do begin
      if x = 0 then begin
        break;
      end;
      if x < 0 then begin
        Textur[0].ActiveAndBind();
      end else begin
        Textur[1].ActiveAndBind();
      end;

      Matrix.Identity;
      Matrix.Translate(x * d, y * d, -4 * d);                 // Matrix verschieben.

      Matrix.Multiply(WorldMatrix, Matrix);                  // Matrixen multiplizieren.
      Matrix.Multiply(FrustumMatrix, Matrix);

      Matrix.Uniform(Matrix_ID);                             // Matrix dem Shader übergeben.
      glDrawArrays(GL_TRIANGLES, 0, Length(Quad)); // Zeichnet einen kleinen Würfel.
    end;
  end;

  ogc.SwapBuffers;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := False;

  Matrix.Free;
  FrustumMatrix.Free;
  WorldMatrix.Free;

  Shader.Free;

  Textur[0].Free;
  Textur[1].Free;

  glDeleteVertexArrays(1, @VBTriangle.VAO);
  glDeleteBuffers(1, @VBTriangle.VBOVertex);
  glDeleteBuffers(1, @VBTriangle.VBOTex);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
const
  step: GLfloat = 0.01;
  scale: GLfloat = 0.1;
begin
  scale := scale * 1.02;
  if scale > 1.0 then begin
    scale := 0.1;
  end;
  //  ScaleMatrix.Identity;
  //  ScaleMatrix.Scale(scale);

  //  RotMatrix.RotateC(step);


  ogcDrawScene(Sender);
end;

//lineal

(*
<b>Vertex-Shader:</b>

Hier ist die Uniform-Variable <b>mat</b> hinzugekommen.
Diese wird im Vertex-Shader deklariert, Bewegungen kommen immer in diesen Shader.
*)
//includeglsl Vertexshader.glsl
//lineal

(*
<b>Fragment-Shader:</b>
*)
//includeglsl Fragmentshader.glsl

end.
