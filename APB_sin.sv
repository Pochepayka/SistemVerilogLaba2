module APB_sin
#(parameter control_reg_ADDR = 4'h0, // адрес контрольного регистра
  parameter output_reg_ADDR = 4'h4)  // адрес регистра, где хранится значение sin
(
    input wire PWRITE,            // сигнал, выбирающий режим записи или чтения (1 - запись, 0 - чтение)
    input wire PCLK,              // сигнал синхронизации
    input wire PSEL,              // сигнал выбора переферии 
    input wire [31:0] PADDR,      // Адрес регистра
    input wire [31:0] PWDATA,     // Данные для записи в регистр
    output reg [31:0] PRDATA = 0,        // Данные, прочитанные из регистра
    input wire PENABLE,           // сигнал разрешения
    output reg PREADY = 0         // сигнал готовности (флаг того, что всё сделано успешно)
);


reg  [31:0] control_reg  = 0; // регистр для записи значения x, где x принимает значения 0,1,2,3....
reg  [31:0] output_reg   = 0; // регистр для хранения результата после вычисления функции sin(x) 


always @(posedge PCLK) 
begin
    if (PSEL && !PWRITE && PENABLE) // Чтение из регистров 
     begin
        case(PADDR)
         4'h0: PRDATA <= control_reg; // чтение по адресу контрольного регистра
         4'h4: PRDATA <= output_reg;  // чтение по адресу выходного регистра
        endcase
        PREADY <= 1'd1; // поднимаем флаг заверешения операции
     end

     else if(PSEL && PWRITE && PENABLE) // запись производится только в контрольный регистр, который хранит значение шага pi/4
     begin
      if(PADDR == control_reg_ADDR)
      begin
        control_reg <= PWDATA;
        PREADY <= 1'd1;    // поднимаем флаг заверешения операции
      end
     end
   
   if (PREADY) // сбрасываем PREADY после выполнения записи или чтения
    begin
      PREADY <= !PREADY;
    end
    
  end

always @(control_reg) begin // вычисление значения sin(x)
 
    if(control_reg% 4 == 0) // если угол = pi*k (tg(pi*k)==0)
    begin
      output_reg <= 0;
    end

    else if((control_reg)%8 == 2) // если угол = pi/2 + 2pi*k (90 градусов)
    begin
      output_reg <= 1;
    end

      else if((control_reg)%8 == 6) // если угол = 3pi/2 + 2pi*k (270 градусов)
    begin
      output_reg <= ~(32'b00000000000000000000000000000001); // обратный код числа -1
    end

    else if(((control_reg)%8 == 1) || ((control_reg)%8 == 3)) // если угол = 3pi/4 + 2pi*k или pi/4 + 2pi*k (45 или 135 градусов)
    begin
      output_reg <= (32'00111111001101010000010011110011); // sqrt(2)/2
    end

    else if(((control_reg)%8 == 5) || ((control_reg)%8 == 7)) // если угол = -3pi/4 + 2pi*k или -pi/4 + 2pi*k (135 или 315 градусов)
    begin
      output_reg <= (32'00111111001101010000010011110011); // -sqrt(2)/2
    end

    else // иначе
    begin
      output_reg <= 32'b01111111111111111111111111111111; // очень большое значение
    end
  
end

//iverilog -g2012 -o APB_sin.vvp APB_sin_tb.sv
//vvp APB_sin.vvp
endmodule