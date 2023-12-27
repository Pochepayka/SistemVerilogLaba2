module APB_master
(
    input wire PCLK,                    // сигнал синхронизации
    input wire PWRITE_MASTER,           // сигнал, выбирающий режим записи или чтения (1 - запись, 0 - чтение)
    output reg PSEL = 0,                // сигнал выбора переферии 
    input wire [31:0] PADDR_MASTER,     // Адрес регистра
    input wire [31:0] PWDATA_MASTER,    // Данные для записи в регистр
    output reg [31:0] PRDATA_MASTER = 0,// Данные, прочитанные из слейва
    output reg PENABLE = 0,             // сигнал разрешения, формирующийся в мастер APB
    input wire PRESET,                  // сигнал сброса
    input wire PREADY,                  // сигнал готовности (флаг того, что всё сделано успешно)
    output reg [31:0] PADDR = 0,        // адрес, который мы будем передавать в слейв
    output reg [31:0] PWDATA = 0,       // данные, которые будут передаваться в слейв,
    input  wire [31:0] PRDATA,          // данные, прочтённые с слейва
    output reg PWRITE = 0               // сигнал записи или чтения на вход слейва
);

task apb_write; // функция записи
input  [31:0] inp_addr;
 input  [31:0] inp_data;
begin
  PSEL = 1'd1;        // поднимаем флаг выбора устройства
  PADDR = inp_addr;   // передаем адрес на входе мастера в слейв
  PWDATA = inp_data;  // передаём данные в слейв
  PWRITE = 1'd1;      // ставим сигнал записи
  PENABLE = 1'd1;     // выдаём разрешение на выполнение действий

  if(PREADY)
   begin
     PSEL = !PSEL;        // убираем сигнал psel
     PENABLE = !PENABLE; // убираем  сигнал PENABLE
   end
end
endtask

task apb_read; //функция чтения из слейва
input [31:0] inp_addr;
begin
  if(!PREADY)
  begin
    PADDR = inp_addr; // передаем адрес на входе мастера в слейв
    PWRITE = 1'd0;
    PSEL = 1'd1;
    PENABLE = 1'd1;
  end
  
  else if(PREADY)
   begin
     PSEL = !PSEL;
     PENABLE = !PENABLE;
   end
end
endtask

// циклы записи и чтения интерфейса APB
always @(posedge PCLK) 
begin
    if(PRESET) // если поднят сигнал сброса
    begin
      PADDR <= 32'b0;
      PWDATA <= 32'b0;
      PWRITE <= 1'b0;
      PSEL <= 1'b0;
      PENABLE <= 1'b0;
      PRDATA_MASTER <= 1'b0;
    end

    else if (!PWRITE_MASTER) // Чтение из регистров 
     begin
        apb_read(PADDR_MASTER); // вызов фунции чтения
     end
    else if (PWRITE_MASTER) // Запись в регистры
     begin
        apb_write(PADDR_MASTER, PWDATA_MASTER);
     end
  end

always @(posedge PREADY) // если pready поднялся в 1
begin
  if (!PWRITE_MASTER)     // если выбрана операция чтение
    begin
     PRDATA_MASTER <=PRDATA; // передаём данные на выход apb мастера
    end
end
endmodule