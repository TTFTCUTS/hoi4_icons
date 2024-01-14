import 'dart:html';
import "dart:math" as Math;
import "dart:typed_data";

import "package:LoaderLib/Loader.dart";
import "package:LoaderLib/Archive.dart";
import "package:archive/archive.dart" as raw;

final Element gallery = querySelector("#gallery")!;
final ImageElement frame = querySelector("#frame")! as ImageElement;

void main() {
  print("Let's make some icons");

  querySelector("#load")!.append(Loader.loadButton(Formats.png, load, multiple: true, caption: "Pick Portraits"));
  querySelector("#save")!.append(Loader.saveButton(Formats.zip, save, filename: () => "icons", caption: "Save Icons"));
}

void load(ImageElement image, String filename) {
  print("Loaded image: $filename");

  final Element container = new DivElement()..className="portrait"..dataset["name"] = filename;

  container.append(image);

  const double ox = 4.25;
  const double oy = 8.25;
  const double angle = -9.5;
  const double scale = 0.2375;

  final CanvasElement canvas = new CanvasElement(width: frame.width, height: frame.height)..className="output";
  final CanvasRenderingContext2D ctx = canvas.context2D;

  magic(image); // I don't know why this makes the canvas act differently, but it makes things less blurry and it doesn't even DO anything significant

  ctx.save();
  ctx.translate(ox, oy);
  ctx.rotate((Math.pi / 360) * angle);
  ctx.scale(scale, scale);

  ctx.drawImage(image, 0, 0);
  ctx.filter = "blur(0.5px)";
  ctx.globalAlpha = 0.5;
  ctx.drawImage(image, 0, 0);

  ctx.restore();
  ctx.drawImage(frame, 0, 0);

  container.append(canvas);

  gallery.append(container);
}

void magic(ImageElement img) {
  final int w = img.width!;
  final int h = img.height!;

  final CanvasElement canvas = new CanvasElement(width:w, height:h);
  final CanvasRenderingContext2D ctx = canvas.context2D;

  ctx.drawImage(img, 0, 0);
}

Future<Archive> save() async {
  final Archive zip = new Archive();

  final ElementList<Element> portraits = querySelectorAll(".portrait");

  for(final Element portrait in portraits) {
    final String filename = portrait.dataset["name"]!;

    final CanvasElement canvas = portrait.querySelector(".output")! as CanvasElement;

    final Blob blob = await canvas.toBlob();

    final ByteBuffer buffer = await Formats.png.readFromFile(new File(<Object>[blob], filename));

    final raw.ArchiveFile file = new raw.ArchiveFile(filename, blob.size, new Uint8ClampedList.view(buffer));
    zip.rawArchive.addFile(file);

    //final ImageElement img = await Formats.png.readObjectFromFile(new File([blob], filename));

    //zip.setFile(filename, img, format: Formats.png);

    print("added $filename to archive");
  }

  return zip;
}
