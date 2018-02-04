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

    procedure CalcCircle;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

type
  TVB = record
    VAO: GLuint;
    VBO: record
      Vertex: GLuint;
    end;
  end;

var
  Linies: array of TVector2f;

  VBRingL: TVB;
  RotMatrix, ScaleMatrix, ProdMatrix: TMatrix;
  Matrix_ID: GLint;

  TextureBuffer: TTexturBuffer;

procedure TForm1.CalcCircle;
const
  Sektoren = 20;
  maxSek = Sektoren * 1;
  r = 1.1 / maxSek;
var
  i: integer;
begin
  SetLength(Linies, maxSek);
  for i := 0 to maxSek - 1 do begin
    Linies[i, 0] := sin(Pi * 2 / Sektoren * i) * r * i;
    Linies[i, 1] := cos(Pi * 2 / Sektoren * i) * r * i;
  end;

  Randomize;
  SetLength(Linies, Sektoren);
  for i := 0 to Sektoren - 1 do begin
    Linies[i, 0] := -1.0 + 1.0 / Sektoren * i * 2;
    Linies[i, 1] := -1.0 + Random * 2;
  end;
  Linies[8]:=vec2(0.4,0.3);
  Linies[9]:=vec2(0.4,-0.3);
  exit;

  SetLength(Linies, 9);
  Linies[0] := vec2(0.0, 0.0);
  Linies[1] := vec2(-0.5, -0.5);
  Linies[2] := vec2(0.5, -0.5);
  Linies[3] := vec2(0.5, 0.5);
  Linies[4] := vec2(-0.5, 0.5);
  Linies[5] := vec2(-1.0, 0.5);
  Linies[6] := vec2(-0.2, 0.25);
  Linies[7] := vec2(-0.2, -0.25);
  Linies[8] := vec2(0.0, 0.0);

end;

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

procedure TForm1.CreateScene;
begin
  CalcCircle;

  glGenVertexArrays(1, @VBRingL.VAO);
  glGenBuffers(1, @VBRingL.VBO);

  TextureBuffer := TTexturBuffer.Create;
  TextureBuffer.LoadTextures('muster.xpm');

  Shader := TShader.Create([FileToStr('Vertexshader.glsl'), FileToStr('Geometrieshader.glsl'), FileToStr('Fragmentshader.glsl')]);
  with Shader do begin
    UseProgram;
    Matrix_ID := UniformLocation('mat');
  end;

  RotMatrix := TMatrix.Create;
  ScaleMatrix := TMatrix.Create;
  //  ScaleMatrix.Scale(0.45);
  ProdMatrix := TMatrix.Create;
end;

procedure TForm1.InitScene;
begin
  TextureBuffer.ActiveAndBind;
  glClearColor(0.6, 0.6, 0.4, 1.0);

  // Ring Links
  glBindVertexArray(VBRingL.VAO);

  glBindBuffer(GL_ARRAY_BUFFER, VBRingL.VBO.Vertex);
  glBufferData(GL_ARRAY_BUFFER, Length(Linies) * SizeOf(TVector2f), Pointer(Linies), GL_STATIC_DRAW);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, nil);
end;

procedure TForm1.ogcDrawScene(Sender: TObject);
begin
  glClear(GL_COLOR_BUFFER_BIT);

  TextureBuffer.ActiveAndBind;

  Shader.UseProgram;

  ProdMatrix.Multiply(ScaleMatrix, RotMatrix);

  // Zeichne linke Scheibe
  ProdMatrix.Push;
  //  ProdMatrix.Translate(-0.5, 0.0, 0.0);
  ProdMatrix.Uniform(Matrix_ID);
  ProdMatrix.Pop;

  glBindVertexArray(VBRingL.VAO);
  glDrawArrays(GL_LINE_STRIP_ADJACENCY, 0, Length(Linies));

  ogc.SwapBuffers;
end;
//code-

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := False;

  TextureBuffer.Free;

  glDeleteVertexArrays(1, @VBRingL.VAO);
  glDeleteBuffers(1, @VBRingL.VBO);

  ProdMatrix.Free;
  RotMatrix.Free;
  ScaleMatrix.Free;

  Shader.Free;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
const
  step: GLfloat = 0.01;
begin
  //  RotMatrix.RotateC(step);
  ogcDrawScene(Sender);
end;

end.
