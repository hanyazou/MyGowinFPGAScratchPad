   string tb_name;
   integer tb_errors;
   integer tb_assertion_failures;
   integer tb_count;
   
   task tb_init();
      tb_count = 0;
      tb_errors = 0;
   endtask

   task tb_begin(input string name);
      tb_name = name;
      tb_assertion_failures = 0;
   endtask
         
   `define tb_assert(cond) do begin assert(cond) else begin $error(`"cond`"); \
      tb_assertion_failures++; \
      end \
   end while (0)
         
   task tb_end();
      tb_count++;
      if (tb_assertion_failures === 0) begin
         $display("testbench: %s ... pass", tb_name);
      end else begin
         $display("testbench: %s ... FAILED", tb_name);
         tb_errors++;
      end
   endtask
         
   task tb_finish();
      $display("");
      if (tb_errors === 0) begin
         $display("testbench: %1d test%0s succeeded", tb_count, tb_count !== 1 ? "s" : "");
      end else begin
         $display("testbench: %1d/%1d test%0s FAILED", tb_errors, tb_count,
            tb_errors !== 1 ? "s" : "");
      end
      $display("");
      $finish;
   endtask
