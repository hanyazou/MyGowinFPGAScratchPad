   `include "h80cpu.svh"
   `include "h80cpu_instmacros.svh"
   initial begin
      mem[16'h0000]=16'h0160;
      mem[16'h0001]=16'h1000;
      mem[16'h0002]=16'h3f20;
      mem[16'h0003]=16'h017f;
      mem[16'h0004]=16'hfe08;
      mem[16'h0005]=16'h0177;
      mem[16'h0006]=16'h0018;
      mem[16'h0007]=16'h0871;
      mem[16'h0008]=16'h017e;
      mem[16'h0009]=16'hfc7f;
      mem[16'h000a]=16'h0176;
      mem[16'h000b]=16'h004e;
      mem[16'h000c]=16'h0861;
      mem[16'h000d]=16'h3cec;
      mem[16'h000e]=16'h3cfd;
      mem[16'h000f]=16'hebbb;
      mem[16'h0010]=16'ha3cc;
      mem[16'h0011]=16'h0439;
      mem[16'h0012]=16'ha8dd;
      mem[16'h0013]=16'h0489;
      mem[16'h0014]=16'h9338;
      mem[16'h0015]=16'h833e;
      mem[16'h0016]=16'ha8cd;
      mem[16'h0017]=16'h0488;
      mem[16'h0018]=16'h8d8f;
      mem[16'h0019]=16'h3c3c;
      mem[16'h001a]=16'ha3cc;
      mem[16'h001b]=16'h0439;
      mem[16'h001c]=16'ha8dd;
      mem[16'h001d]=16'h0489;
      mem[16'h001e]=16'h8338;
      mem[16'h001f]=16'h0168;
      mem[16'h0020]=16'h0800;
      mem[16'h0021]=16'hf883;
      mem[16'h0022]=16'h0170;
      mem[16'h0023]=16'h0010;
      mem[16'h0024]=16'h0390;
      mem[16'h0025]=16'h3cb4;
      mem[16'h0026]=16'h0160;
      mem[16'h0027]=16'h009a;
      mem[16'h0028]=16'h01c0;
      mem[16'h0029]=16'h0170;
      mem[16'h002a]=16'h0018;
      mem[16'h002b]=16'h01f0;
      mem[16'h002c]=16'h08b1;
      mem[16'h002d]=16'h00f8;
      mem[16'h002e]=16'h0010;
      mem[16'h002f]=16'h0000;
      mem[16'h0030]=16'hfbb8;
      mem[16'h0031]=16'h0160;
      mem[16'h0032]=16'h0020;
      mem[16'h0033]=16'h0350;
      mem[16'h0034]=16'h1820;
      mem[16'h0035]=16'h1100;
      mem[16'h0036]=16'h3981;
      mem[16'h0037]=16'h00f8;
      mem[16'h0038]=16'h0017;
      mem[16'h0039]=16'h0000;
      mem[16'h003a]=16'h8ee8;
      mem[16'h003b]=16'h0961;
      mem[16'h003c]=16'h0170;
      mem[16'h003d]=16'hff9e;
      mem[16'h003e]=16'h0380;
      mem[16'h003f]=16'h00f8;
      mem[16'h0040]=16'h002a;
      mem[16'h0041]=16'h0000;
      mem[16'h0042]=16'h8ff8;
      mem[16'h0043]=16'h1000;
      mem[16'h0044]=16'h110d;
      mem[16'h0045]=16'h3910;
      mem[16'h0046]=16'h110a;
      mem[16'h0047]=16'h3910;
      mem[16'h0048]=16'h0971;
      mem[16'h0049]=16'h0170;
      mem[16'h004a]=16'hff7a;
      mem[16'h004b]=16'h0380;
      mem[16'h004c]=16'h0001;
      mem[16'h004d]=16'h0168;
      mem[16'h004e]=16'h000a;
      mem[16'h004f]=16'hf448;
      mem[16'h0050]=16'h0170;
      mem[16'h0051]=16'h0004;
      mem[16'h0052]=16'h03d0;
      mem[16'h0053]=16'h0847;
      mem[16'h0054]=16'h00f8;
      mem[16'h0055]=16'h0030;
      mem[16'h0056]=16'h0000;
      mem[16'h0057]=16'h8448;
      mem[16'h0058]=16'h0168;
      mem[16'h0059]=16'h0000;
      mem[16'h005a]=16'h3948;
      mem[16'h005b]=16'h0002;
end
