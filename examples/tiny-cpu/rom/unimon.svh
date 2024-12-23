   `include "h80cpu.svh"
   `include "h80cpu_instmacros.svh"
   initial begin
      mem[16'h0000]=16'h0160;
      mem[16'h0001]=16'h0100;
      mem[16'h0002]=16'h01e0;
      mem[16'h0003]=16'hffff;
      mem[16'h0004]=16'hffff;
      mem[16'h0005]=16'hffff;
      mem[16'h0006]=16'hffff;
      mem[16'h0007]=16'hffff;
      mem[16'h0008]=16'h0160;
      mem[16'h0009]=16'h01e0;
      mem[16'h000a]=16'h01e0;
      mem[16'h000b]=16'hffff;
      mem[16'h000c]=16'h0160;
      mem[16'h000d]=16'h01ee;
      mem[16'h000e]=16'h01e0;
      mem[16'h000f]=16'hffff;
      mem[16'h0010]=16'hffff;
      mem[16'h0011]=16'hffff;
      mem[16'h0012]=16'hffff;
      mem[16'h0013]=16'hffff;
      mem[16'h0014]=16'hffff;
      mem[16'h0015]=16'hffff;
      mem[16'h0016]=16'hffff;
      mem[16'h0017]=16'hffff;
      mem[16'h0018]=16'hffff;
      mem[16'h0019]=16'hffff;
      mem[16'h001a]=16'hffff;
      mem[16'h001b]=16'hffff;
      mem[16'h001c]=16'hffff;
      mem[16'h001d]=16'hffff;
      mem[16'h001e]=16'hffff;
      mem[16'h001f]=16'hffff;
      mem[16'h0020]=16'hffff;
      mem[16'h0021]=16'hffff;
      mem[16'h0022]=16'hffff;
      mem[16'h0023]=16'hffff;
      mem[16'h0024]=16'hffff;
      mem[16'h0025]=16'hffff;
      mem[16'h0026]=16'hffff;
      mem[16'h0027]=16'hffff;
      mem[16'h0028]=16'hffff;
      mem[16'h0029]=16'hffff;
      mem[16'h002a]=16'hffff;
      mem[16'h002b]=16'hffff;
      mem[16'h002c]=16'hffff;
      mem[16'h002d]=16'hffff;
      mem[16'h002e]=16'hffff;
      mem[16'h002f]=16'hffff;
      mem[16'h0030]=16'hffff;
      mem[16'h0031]=16'hffff;
      mem[16'h0032]=16'hffff;
      mem[16'h0033]=16'hffff;
      mem[16'h0034]=16'hffff;
      mem[16'h0035]=16'hffff;
      mem[16'h0036]=16'hffff;
      mem[16'h0037]=16'hffff;
      mem[16'h0038]=16'hffff;
      mem[16'h0039]=16'hffff;
      mem[16'h003a]=16'hffff;
      mem[16'h003b]=16'hffff;
      mem[16'h003c]=16'hffff;
      mem[16'h003d]=16'hffff;
      mem[16'h003e]=16'hffff;
      mem[16'h003f]=16'hffff;
      mem[16'h0040]=16'hffff;
      mem[16'h0041]=16'hffff;
      mem[16'h0042]=16'hffff;
      mem[16'h0043]=16'hffff;
      mem[16'h0044]=16'hffff;
      mem[16'h0045]=16'hffff;
      mem[16'h0046]=16'hffff;
      mem[16'h0047]=16'hffff;
      mem[16'h0048]=16'hffff;
      mem[16'h0049]=16'hffff;
      mem[16'h004a]=16'hffff;
      mem[16'h004b]=16'hffff;
      mem[16'h004c]=16'hffff;
      mem[16'h004d]=16'hffff;
      mem[16'h004e]=16'hffff;
      mem[16'h004f]=16'hffff;
      mem[16'h0050]=16'hffff;
      mem[16'h0051]=16'hffff;
      mem[16'h0052]=16'hffff;
      mem[16'h0053]=16'hffff;
      mem[16'h0054]=16'hffff;
      mem[16'h0055]=16'hffff;
      mem[16'h0056]=16'hffff;
      mem[16'h0057]=16'hffff;
      mem[16'h0058]=16'hffff;
      mem[16'h0059]=16'hffff;
      mem[16'h005a]=16'hffff;
      mem[16'h005b]=16'hffff;
      mem[16'h005c]=16'hffff;
      mem[16'h005d]=16'hffff;
      mem[16'h005e]=16'hffff;
      mem[16'h005f]=16'hffff;
      mem[16'h0060]=16'hffff;
      mem[16'h0061]=16'hffff;
      mem[16'h0062]=16'hffff;
      mem[16'h0063]=16'hffff;
      mem[16'h0064]=16'hffff;
      mem[16'h0065]=16'hffff;
      mem[16'h0066]=16'hffff;
      mem[16'h0067]=16'hffff;
      mem[16'h0068]=16'hffff;
      mem[16'h0069]=16'hffff;
      mem[16'h006a]=16'hffff;
      mem[16'h006b]=16'hffff;
      mem[16'h006c]=16'hffff;
      mem[16'h006d]=16'hffff;
      mem[16'h006e]=16'hffff;
      mem[16'h006f]=16'hffff;
      mem[16'h0070]=16'hffff;
      mem[16'h0071]=16'hffff;
      mem[16'h0072]=16'hffff;
      mem[16'h0073]=16'hffff;
      mem[16'h0074]=16'hffff;
      mem[16'h0075]=16'hffff;
      mem[16'h0076]=16'hffff;
      mem[16'h0077]=16'hffff;
      mem[16'h0078]=16'hffff;
      mem[16'h0079]=16'hffff;
      mem[16'h007a]=16'hffff;
      mem[16'h007b]=16'hffff;
      mem[16'h007c]=16'hffff;
      mem[16'h007d]=16'hffff;
      mem[16'h007e]=16'hffff;
      mem[16'h007f]=16'hffff;
      mem[16'h0080]=16'h0166;
      mem[16'h0081]=16'h0ff0;
      mem[16'h0082]=16'h3f26;
      mem[16'h0083]=16'h0160;
      mem[16'h0084]=16'h01de;
      mem[16'h0085]=16'h01c0;
      mem[16'h0086]=16'h0166;
      mem[16'h0087]=16'h8000;
      mem[16'h0088]=16'h0160;
      mem[16'h0089]=16'h0f10;
      mem[16'h008a]=16'h3460;
      mem[16'h008b]=16'h0160;
      mem[16'h008c]=16'h0f17;
      mem[16'h008d]=16'h3460;
      mem[16'h008e]=16'h0160;
      mem[16'h008f]=16'h0f15;
      mem[16'h0090]=16'h3460;
      mem[16'h0091]=16'h1649;
      mem[16'h0092]=16'h0160;
      mem[16'h0093]=16'h0f19;
      mem[16'h0094]=16'h3860;
      mem[16'h0095]=16'he666;
      mem[16'h0096]=16'h0160;
      mem[16'h0097]=16'h0f1d;
      mem[16'h0098]=16'h3860;
      mem[16'h0099]=16'h1864;
      mem[16'h009a]=16'he444;
      mem[16'h009b]=16'h0160;
      mem[16'h009c]=16'h01ee;
      mem[16'h009d]=16'h01c0;
      mem[16'h009e]=16'h0170;
      mem[16'h009f]=16'hfff4;
      mem[16'h00a0]=16'h0a80;
      mem[16'h00a1]=16'h0164;
      mem[16'h00a2]=16'h0172;
      mem[16'h00a3]=16'h0160;
      mem[16'h00a4]=16'h0158;
      mem[16'h00a5]=16'h01c0;
      mem[16'h00a6]=16'h0164;
      mem[16'h00a7]=16'h018c;
      mem[16'h00a8]=16'h0160;
      mem[16'h00a9]=16'h0158;
      mem[16'h00aa]=16'h01c0;
      mem[16'h00ab]=16'h0001;
      mem[16'h00ac]=16'h3a64;
      mem[16'h00ad]=16'hc666;
      mem[16'h00ae]=16'h0084;
      mem[16'h00af]=16'h0104;
      mem[16'h00b0]=16'h3c64;
      mem[16'h00b1]=16'h0160;
      mem[16'h00b2]=16'h01ee;
      mem[16'h00b3]=16'h01c0;
      mem[16'h00b4]=16'h0114;
      mem[16'h00b5]=16'h0841;
      mem[16'h00b6]=16'h0170;
      mem[16'h00b7]=16'hffe8;
      mem[16'h00b8]=16'h01f0;
      mem[16'h00b9]=16'h0a0d;
      mem[16'h00ba]=16'h6e55;
      mem[16'h00bb]=16'h7669;
      mem[16'h00bc]=16'h7265;
      mem[16'h00bd]=16'h6173;
      mem[16'h00be]=16'h206c;
      mem[16'h00bf]=16'h6f4d;
      mem[16'h00c0]=16'h696e;
      mem[16'h00c1]=16'h6f74;
      mem[16'h00c2]=16'h2072;
      mem[16'h00c3]=16'h3848;
      mem[16'h00c4]=16'h0d30;
      mem[16'h00c5]=16'h000a;
      mem[16'h00c6]=16'h205d;
      mem[16'h00c7]=16'h4500;
      mem[16'h00c8]=16'h7272;
      mem[16'h00c9]=16'h726f;
      mem[16'h00ca]=16'h6920;
      mem[16'h00cb]=16'h6568;
      mem[16'h00cc]=16'h0d78;
      mem[16'h00cd]=16'h000a;
      mem[16'h00ce]=16'h7245;
      mem[16'h00cf]=16'h6f72;
      mem[16'h00d0]=16'h2072;
      mem[16'h00d1]=16'h7273;
      mem[16'h00d2]=16'h6365;
      mem[16'h00d3]=16'h0a0d;
      mem[16'h00d4]=16'h4500;
      mem[16'h00d5]=16'h7272;
      mem[16'h00d6]=16'h726f;
      mem[16'h00d7]=16'h0a0d;
      mem[16'h00d8]=16'h2000;
      mem[16'h00d9]=16'h003a;
      mem[16'h00da]=16'h3a20;
      mem[16'h00db]=16'h0020;
      mem[16'h00dc]=16'h303a;
      mem[16'h00dd]=16'h3030;
      mem[16'h00de]=16'h3030;
      mem[16'h00df]=16'h3030;
      mem[16'h00e0]=16'h4631;
      mem[16'h00e1]=16'h0d46;
      mem[16'h00e2]=16'h000a;
      mem[16'h00e3]=16'h3953;
      mem[16'h00e4]=16'h3330;
      mem[16'h00e5]=16'h3030;
      mem[16'h00e6]=16'h3030;
      mem[16'h00e7]=16'h4346;
      mem[16'h00e8]=16'h0a0d;
      mem[16'h00e9]=16'h5200;
      mem[16'h00ea]=16'h5453;
      mem[16'h00eb]=16'h3320;
      mem[16'h00ec]=16'h4838;
      mem[16'h00ed]=16'h0a0d;
      mem[16'h00ee]=16'hff00;
      mem[16'h00ef]=16'h0002;
      mem[16'h00f0]=16'h1000;
      mem[16'h00f1]=16'h3320;
      mem[16'h00f2]=16'h0002;
      mem[16'h00f3]=16'h0160;
      mem[16'h00f4]=16'h01e6;
      mem[16'h00f5]=16'h3320;
      mem[16'h00f6]=16'h0002;
      mem[16'h00f7]=16'h1000;
      mem[16'h00f8]=16'h3940;
      mem[16'h00f9]=16'h0002;
end
