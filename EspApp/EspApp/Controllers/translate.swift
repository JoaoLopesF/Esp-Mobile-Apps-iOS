/* ***********
 * Project   : Esp-Idf-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : MainController - main controller and main code in app
 * Comments  : Uses a singleton pattern to share instance to all app
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

/*
 // TODO:
 */

import Foundation
import UIKit

public class MainController: NSObject, BLEDelegate {
    
    /////// Singleton
    
    static private var instance : MainController {
        return sharedInstance
    }
    
    private static let sharedInstance = MainController()
    
    // Singleton pattern method
    
    static func getInstance() -> MainController {
        return self.instance
    }
    
    ////// BLE instance
    
    #if !targetEnvironment(simulator) // Real device ? (not for simulator)
    
    private let ble = BLE.getInstance()
    
    #endif
    
    ////// Objects
    
    var navigationController:UINavigationController? = nil // Navegation
    
    var storyBoardMain: UIStoryboard? = nil // Story board Main
    
    @objc var timerSeconds: Timer? = nil // Timer in seconds
    
    var imageBattery: UIImage? = nil // Battery
    
    ///// Variables
    
    public let versionAPP:String = "0.1.0" // Version of this APP
    
    private (set) var versionDevice: String = "?" // Version of BLE device
    private (set) var percentBattery = "100%" // Battery
    
    private var tempoFeedback: Int = 0 // Tempo para envio de feedbacks
    public var enviarFeedback : Bool = false
    
    public var emExecucao : Bool = false
    
    public var tempoAtivo : Int = 0     // Tempo da ultima atividade
    private var saindo : Bool = false
    
    
    // Debug
    
    private var emDepuracao : Bool = true // Todo tela de config
    
    // Energia
    
    private (set) var energiaCarregando : Bool = false
    
    //    // Tratador de excecoes
    //
    //    private var mExceptionHandler : ExceptionHandler
    
    ////// Configuracoes
    
    public var cfgModoSilenc : Bool = true
    public var cfgModoPowerSave : Bool = true
    public var cfgOrdemExibSessoes : Character = "O" // O-> Orig / N-> Nome
    
    // BLE
    
    private var bleProcessarRetorno:Bool = false // Processa retornos recebidos
    private var bleNrMsgEnviadas:Int = 0 // Mensagens enviadas
    private var bleNrMsgReceb:Int = 0 // Mensagens recebidas
    private var bleNrMsgOKReceb:Int = 0 // Mensagens OK recebidads
    
    private var bleTempoInicEnvio:Int64 = 0 // Tempo
    
    private var bleProcessarRetornos:Bool = false // Processa os retornos ?
    
    private var bleAguardandoOK:Bool = false // Aguardando OK ?
    
    private let timeoutBLE:Int = 5 // Timeout do BLE
    private var bleTimeout:Int = 0 // Timeout do BLE
    private var bleVerifTimeout:Bool = true // Verificar timeout ?
    
    private var bleAbortandoConexao : Bool = false  // Abortando conexao
    
    //    private var bleDebug : String? = nil // Buffer de debug de mensagens enviadas/recebidas
    private var bleStatusAtivo : Bool = false // Status do BLE ativo no rodape ?
    
    /////////////////// Init
    
    // Init
    
    override init() {
        super.init()
        
        // Inicializar
        
        inicializar ()
        
    }
    
    /////////////////// Methods
    
    private func ativaTimer(ativa : Bool) {
        
        // Timer of seconds
        
        debugV("activate:", ativa)
        
        // Zera veriaveis
        
        tempoFeedback = 0
        
        //        if let playVC = navigationController?.topViewController as? PlayViewController { // EstÃ¡ na tela do play ?
        //            playVC.tempoExecucao = 0
        //            playVC.tempoInicioExecSegmento = 0
        //        }
        
        // Ativa ?
        
        if ativa {
            
            if timerSeconds != nil {
                
                // Desativa antes o anterior
                
                timerSeconds?.invalidate()
                
            }
            
            // Ativa o timer
            
            self.timerSeconds = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerTickSeconds), userInfo: nil, repeats: true)
            
        } else {
            
            // Cancela timer
            
            if timerSeconds != nil {
                
                self.timerSeconds?.invalidate()
            }
        }
        
    }
    
    @objc private func timerTickSeconds() {
        
        // Timer a cada segundo - somente quando conectado
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        if ble.connected == false {
            
            debugV("Timer - desconectado")
            
            ativaTimer(ativa: false)
            
            return
        }
        
        if self.bleStatusAtivo {
            exibirStatusBle(ativo: false)
        }
        
        //        if debugV() {
        //            debugV("bleVerifTimeout:", bleVerifTimeout, " em exec ", emExecucao)
        //        }
        
        // Timeout de envio
        
        if bleVerifTimeout == true && emDepuracao == false {
            
            bleTimeout -= 1
            
            if bleTimeout <= 0 {
                
                debugE("*** Timeout")
                
                bleAbortarConexao(mensagem: "Sem resposta do EspApp via BT (cod B7)");
                
                return;
            }
        }
        
        #endif
        
        // Verifica inatividade
        
        if let _:MainMenuViewController = navigationController?.topViewController as? MainMenuViewController { // In main menu ?
            
            // Tempo restante para entrar em inatividade
            
            self.tempoAtivo -= 1
            
            //debugV("Tempo ativo = " + mTempoAtivo);
            
            if tempoAtivo <= 0 {
                
                // Aborta conexao
                
                bleAbortarConexao(mensagem: "O EspApp foi desligado, devido ter atingido tempo mÃ¡ximo de inatividade \(Settings.timeMaxInactivity)");
                return
            }
            
        } else { // For others - set it as active
            
            tempoAtivo = Settings.timeMaxInactivity
            
        }
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        if ble.sendingNow == false && enviarFeedback == true && MensagensBluetooth.filaMensagens.count == 0 {
            
            // Envia feedback periodicamente
            
            tempoFeedback += 1
            
            if tempoFeedback == Settings.timeSendFeedback {
                
                bleEnviarFeedback()
                tempoFeedback = 0
                
            }
        }
        
        #endif
        
    }
    
    public func inicializarVariaveis() {
        
        // Inicializa as variaveis de controle
        
        emExecucao = false
        
        bleProcessarRetornos = false
        bleAguardandoOK = false
        bleVerifTimeout = false
        bleTimeout = 0
        bleNrMsgReceb = 0
        bleNrMsgOKReceb = 0
        bleNrMsgEnviadas = 0
        
        enviarFeedback = false
        
        tempoAtivo = Settings.timeMaxInactivity
        
        
    }
    
    func showVCMainMenu () {
        
        // Show the main menu view controller
        
        if storyBoardMain == nil {
            storyBoardMain = UIStoryboard(name: "Main", bundle: nil)
        }
        
        DispatchQueue.main.async {
            
            // Atualiza a UI
            
            let mainMenuVC = self.storyBoardMain?.instantiateViewController(withIdentifier: "Main menu") as? MainMenuViewController
            
            self.navigationController?.pushViewController(mainMenuVC!, animated: true)
        }
        
    }
    
    func showVCDisconnected(messagem: String) {
        
        // Show disconnected view controller
        
        if storyBoardMain == nil {
            storyBoardMain = UIStoryboard(name: "Main", bundle: nil)
        }
        
        // Returns to VC root
        
        DispatchQueue.main.async {
            
            self.navigationController?.popToRootViewController(animated:false)
            
            //Show disconnected view controller
            
            if self.storyBoardMain == nil {
                self.storyBoardMain = UIStoryboard(name: "Main", bundle: nil)
            }
            
            if let disconnectVC = self.storyBoardMain?.instantiateViewController(withIdentifier: "Disconnected") as? DisconnectedViewController {
                
                self.navigationController?.pushViewController(disconnectVC, animated: false)
                
                disconnect.message = messagem
            }
        }
    }
    
    private func showStatusBattery(retiraCampo: RetiraCampo) {
        
        // Exibir o status da Battery, pela mensagem recebida
        
        let energia : String = retiraCampo.getCampo(2)
        let leituraVBat : Int = retiraCampo.getCampoInt(3)
        
        debugD("energia=", energia, "leitura vbat=", leituraVBat)
        
        // Mostra icon no status
        
        var voltagem: Float = ((Float(4.403) * Float(leituraVBat) / Float(3455.0))) // Leitura calibrada 3v8 -> 3455
        
        voltagem = Util.arredonda(voltagem, 2)
        
        debugV("volts ->", voltagem, "v")
        
        // Exibe o icone da Battery
        
        energiaCarregando = (energia == "VUSB")
        
        percentBattery = ""
        
        if (energiaCarregando) { // Carregando via USB
            
            imageBattery = #imageLiteral(resourceName: "Battery7_vusb")
            percentBattery = "Usb"
            
        } else { // Nao carregando, le a voltagem
            
            if voltagem >= 4.2 {
                imageBattery = #imageLiteral(resourceName: "Battery6_alta")
            } else if voltagem >= 3.9 {
                imageBattery = #imageLiteral(resourceName: "Battery6_alta")
            } else if voltagem >= 3.7 {
                imageBattery = #imageLiteral(resourceName: "Battery5_media_alta")
            } else if voltagem >= 3.5 {
                imageBattery = #imageLiteral(resourceName: "Battery4_media")
            } else if voltagem >= 3.3 {
                imageBattery = #imageLiteral(resourceName: "Battery3_baixa_media")
            } else if voltagem >= 3.0 {
                imageBattery = #imageLiteral(resourceName: "Battery2_baixa")
            } else {
                imageBattery = #imageLiteral(resourceName: "Battery1_muito_baixa")
            }
            
            // Calcula o %
            
            var percent:Int = 0
            
            if voltagem >= 2.5 {
                voltagem -= 2.5 // Limite inferior // TODO: ver isto
                percent = Int(Util.arredonda(((voltagem * 100.0) / 1.7), 0))
                if percent > 100 {
                    percent = 100
                }
            } else {
                percent = 0
            }
            percentBattery = "\(percent)%"
        }
        
        // Atualiza a tela
        
        showStatusBattery()
        
    }
    
    func exibirImagemPacote(pacoteAVS: PacoteAVS_v1, imageView:UIImageView) {
        
        // Exibe a imagem do pacote
        
        var imagem:UIImage! = nil
        
        if pacoteAVS.nomeArquivoImagem > "" {
            
            // Diretorio do pacote
            
            let dirPacote : String = self.diretorioPacotesAVS + "/" + pacoteAVS.nomeDiretorio
            
            // Carrega a imagem
            
            let pathImagem : String =  dirPacote + "/imagens/" + pacoteAVS.nomeArquivoImagem
            
            if Arquivo.existe(path: pathImagem) {
                
                imagem = UtilUI.carregarImagemArquivo(path: pathImagem)
            }
            
        } else {
            
            // Recomendada ?
            
            if pacoteAVS.tipoPacoteAVS == "Recomendadas" && pacoteAVS.sessoesPacoteAVS.count > 0 {
                
                // Exibe a imagem do pacote original
                
                let codigo: String = pacoteAVS.sessoesPacoteAVS[0].codigoPacote // Pega o codigo da primeira sessao
                
                if let pacoteOrig: PacoteAVS_v1 = procuraPacoteAVS(codigoPacote:codigo) {
                    
                    exibirImagemPacote(pacoteAVS: pacoteOrig, imageView: imageView)
                    
                } else {
                    
                    imagem = UIImage (named: "pacote_recom")
                }
                
            } else {
                
                
                // Imagem default
                
                switch pacoteAVS.tipoPacoteAVS {
                case "Recentes":
                    imagem = UIImage (named: "pacote_recent")
                case "Favoritas":
                    imagem = UIImage (named: "pacote_favor")
                    //                case "Recomendadas":
                //                    imagem = UIImage (named: "pacote_recom")
                case "Energizacao":
                    imagem = UIImage (named: "pacote_energ")
                case "Relaxamento":
                    imagem = UIImage (named: "pacote_relax")
                case "Bem_Estar_Saude":
                    imagem = UIImage (named: "pacote_saude")
                case "Aprendizado":
                    imagem = UIImage (named: "pacote_aprend")
                case "Sono":
                    imagem = UIImage (named: "pacote_sono")
                case "Terapeutica":
                    imagem = UIImage (named: "pacote_terap")
                case "Diagnosticos":
                    imagem = UIImage (named: "pacote_diagn")
                case "Diversas":
                    imagem = UIImage (named: "pacote_divers")
                default:
                    break
                }
            }
        }
        
        // Exibe a imagem
        
        if imagem != nil {
            imageView.image = imagem
        }
        
    }
    
    func showStatusBattery () {
        
        // Exibir o status da Battery, salvos anteriormente
        
        var imageViewBattery: UIImageView!
        var labelPercentBattery: UILabel!
        
        if let menuPrincipalVC = navigationController?.topViewController as? MainMenuViewController {
            labelPercentBattery = menuPrincipalVC.labelPercentBattery
            imageViewBattery = menuPrincipalVC.imageViewBattery
        } else if let menuBaixarVC = navigationController?.topViewController as? MenuBaixarViewController {
            labelPercentBattery = menuBaixarVC.labelPercentBattery
            imageViewBattery = menuBaixarVC.imageViewBattery
        } else if let menuPacotesAVSVC = navigationController?.topViewController as? MenuPacotesAVSViewController {
            labelPercentBattery = menuPacotesAVSVC.labelPercentBattery
            imageViewBattery = menuPacotesAVSVC.imageViewBattery
        } else if let playVC = navigationController?.topViewController as? PlayViewController {
            labelPercentBattery = playVC.labelPercentBattery
            imageViewBattery = playVC.imageViewBattery
        } else if let playInicioVC = navigationController?.topViewController as? PlayInicioViewController {
            labelPercentBattery = playInicioVC.labelPercentBattery
            imageViewBattery = playInicioVC.imageViewBattery
        } else if let playFimVC = navigationController?.topViewController as? PlayFimViewController {
            labelPercentBattery = playFimVC.labelPercentBattery
            imageViewBattery = playFimVC.imageViewBattery
        }
        
        // Atualiza a UI
        
        if labelPercentBattery != nil {
            
            DispatchQueue.main.async {
                imageViewBattery.image = self.imageBattery
                labelPercentBattery.text = self.percentBattery
            }
        }
    }
    
    func exibirStatusBle (ativo:Bool) {
        
        // Exibir o status do BLE (icone no rodape)
        
        var imageViewBluetooth: UIImageView!
        
        if let menuPrincipalVC = navigationController?.topViewController as? MainMenuViewController {
            imageViewBluetooth = menuPrincipalVC.imageViewBluetooth
        } else if let menuBaixarVC = navigationController?.topViewController as? MenuBaixarViewController {
            imageViewBluetooth = menuBaixarVC.imageViewBluetooth
        } else if let menuPacotesAVSVC = navigationController?.topViewController as? MenuPacotesAVSViewController {
            imageViewBluetooth = menuPacotesAVSVC.imageViewBluetooth
        } else if let playVC = navigationController?.topViewController as? PlayViewController {
            imageViewBluetooth = playVC.imageViewBluetooth
        } else if let playInicioVC = navigationController?.topViewController as? PlayInicioViewController {
            imageViewBluetooth = playInicioVC.imageViewBluetooth
        } else if let playFimVC = navigationController?.topViewController as? PlayFimViewController {
            imageViewBluetooth = playFimVC.imageViewBluetooth
        }
        
        // Atualiza a UI
        
        if imageViewBluetooth != nil {
            
            DispatchQueue.main.async {
                imageViewBluetooth.image = (ativo) ? #imageLiteral(resourceName: "bt_icon") : #imageLiteral(resourceName: "bt_icon_inativo")
            }
        }
        
        self.bleStatusAtivo = true
        
        //        // Retorna  para inativo apÃ³s um tempo
        //
        //        if ativo && exibiu {
        //
        //            debugV("")
        //            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
        //               self.exibirStatusBle(ativo: false)
        //            }
        //            debugV("")
        //
        //        }
    }
    
    
    ////// BLE
    
    public func bleProcurarDispositivoLigado() {
        
        // Inicia a procura
        
        debugV("Iniciando a procura ...")
        
        // EstÃ¡ na tela da conexao ?
        
        if let conectandoVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
            
            conectandoVC.labelMensagemConectando.text = "Iniciando a procura ..."
            
        }
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        ble.startScan("RelaxMind")
        
        #endif
    }
    
    private func bleConectou () {
        
        // Conexao OK
        
        // Ativa o timer
        
        ativaTimer(ativa: true)
        
        // Mensagem inicial
        
        bleEnviarMensagem(MensagensBluetooth.geraMensagem_Inicial(), true)
        
        // Enviar feedbacks
        
        enviarFeedback = true
        
    }
    
    func bleAbortarConexao(mensagem : String) {
        
        // Aborta processamentos, audio, conexao, etc.
        
        if bleAbortandoConexao { // evitar mensagens em loop
            return
        }
        
        // JÃ¡ abortado ?
        
        if let _ = navigationController?.topViewController as? DisconnectedViewController {
            return
        }
        
        // Aborta
        
        bleAbortandoConexao = true
        
        debugV("msg=" + mensagem)
        
        // Limpa fila de mensagens
        
        MensagensBluetooth.filaMensagens.removeAll()
        
        // Tela do play
        
        let playVC:PlayViewController? = navigationController?.topViewController as? PlayViewController
        
        // Parar a execucao
        
        if emExecucao {
            
            // Finaliza a sessao em execucao
            
            if playVC != nil { // EstÃ¡ na tela do play ?
                
                playVC?.finalizarSessaoAVS(modo: "Erro")
                
            }
            
        } else {
            
            // Mensagem Desligar
            
            #if !targetEnvironment(simulator) // Dispositivo real
            
            if ble.connected {
                bleEnviarMensagem((!energiaCarregando) ? MensagensBluetooth.MENSAGEM_DESLIGAR : MensagensBluetooth.MENSAGEM_FINALIZAR, false)
            }
            
            #endif
        }
        
        // Aborta timers
        
        ativaTimer(ativa: false)
        
        // Fecha conexao Bluetooth
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        ble.disconnectPeripheral()
        
        #endif
        
        // Aborta fragmento play (parar o audio, etc..)
        
        if playVC != nil { // EstÃ¡ na tela do play ?
            
            playVC?.aborta()
            
        }
        
        // Variaveis
        
        inicializarVariaveis()
        
        // Debug
        
        // TODO: Fazer isto ->  mostrarDebug(getString(R.string.conexo_abortada) + mensagem)
        
        // Exibe tela de desconexao (com a mensagem)
        
        showVCDisconnected(mensagem: mensagem)
        
        // Indica final desta rotina
        
        bleAbortandoConexao = false
        
    }
    
    func bleEnviarMensagem(_ mensagem:String, _ processarRetorno:Bool) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Envia uma mensagem unica
        
        if !ble.connected || ble.sendingNow {
            return
        }
        
        if (mensagem.count == 0) {
            debugW("Mensagem vazia")
            return
        }
        
        if MensagensBluetooth.filaMensagens.count > 0 {
            debugE("Fila de mensagens nao vazia")
            return
        }
        
        // Coloca na fila
        
        MensagensBluetooth.filaMensagens.append(mensagem)
        
        // Envia a mensagem
        
        bleEnviarMensagensFila(processarRetorno)
        
        #endif
    }
    
    func bleEnviarMensagensFila(_ processarRetornos: Bool) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Envia as mensagens que estao na fila de transmissao
        
        if !ble.connected || ble.sendingNow {
            return
        }
        
        if MensagensBluetooth.filaMensagens.count == 0 {
            debugE("Fila de mensagens vazia")
            return
        } else if !processarRetornos && MensagensBluetooth.filaMensagens.count > 1 {
            debugE("Para nao processar retornos a fila de mensagens deve ter somente uma mensagem")
            return
        }
        
        // Processar mensagens de resposta recebidas
        
        bleProcessarMensagens(processarRetornos)
        
        // Envia as mensagem da fila
        
        debugV("enviando ...")
        
        // Reinicializa o tempo para feedbacks
        
        tempoFeedback = 0
        
        // Envia as mensagens da fila via Bluetooth
        
        if MensagensBluetooth.filaMensagens.count == 0 {
            debugW("fila de mensagens vazia")
            return
        }
        
        debugV("Fila de mensagens a Enviar:", MensagensBluetooth.filaMensagens)
        
        // Enviando todas mensagens em uma unica vez -
        
        var mensagens: String = ""
        
        bleNrMsgEnviadas = 0
        
        for fila: String in MensagensBluetooth.filaMensagens {
            mensagens.append(fila)
            mensagens.append("\n")
            bleNrMsgEnviadas+=1
        }
        
        // Limpa a fila
        
        MensagensBluetooth.filaMensagens.removeAll()
        
        // Exibe uma mensagem
        
        exibirStatusBle(ativo: true)
        
        mostrarMensagemStatus("Comunicando com o EspApp ...")
        
        // Envia a mensagem via BLE
        
        if ble.connected {
            ble.send(mensagens)
        }
        
        // Processa as mensagens de retorno ?
        
        if bleProcessarRetornos == true { // Mensagens normais
            
            // Aguardar retorno OK -> ativa timer para timeout para este retorno
            
            bleAguardandoOK = true
            
            bleTimeout = timeoutBLE
            bleVerifTimeout = true
            
            //TODO:            mostrarMensagemStatus(getString(R.string.aguardando_resposta_relax_mind, mNrMsgEnviadas))
            
        } else { // Algumas mensagens de ajustes nao recebem retorno, para agilizar a comunicacao, como no caso do slider do brilho
            
            // Sem aguardar mensagem de OK -> Sem timeout
            
            bleAguardandoOK = false
            
            bleTimeout = 0
            bleVerifTimeout = false
            
            //TODO: mostrarMensagemStatus("", 500)
            
        }
        
        #endif
    }
    
    func bleEnviarFeedback() {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Envia feedback a cada segundo
        
        debugV("")
        
        // Se a fila estiver cheia, ou enviando alngo no BLE, ignora
        
        if MensagensBluetooth.filaMensagens.count > 0 || ble.sendingNow {
            return
        }
        
        // Envia mensagem
        
        bleEnviarMensagem(MensagensBluetooth.MENSAGEM_FEEDBACK, true)
        
        #endif
    }
    
    func bleProcessarMensagens(_ processarRetornos:Bool) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Processa retornos ?
        
        // Comeca a processar as mensagens na fila
        
        if MensagensBluetooth.filaMensagens.count == 0 {
            self.bleProcessarRetorno = false
            return
        }
        
        // Seta variaveis para isto
        
        bleNrMsgEnviadas = 0
        bleNrMsgOKReceb = 0
        bleNrMsgReceb = 0
        
        bleTempoInicEnvio = Util.milisegundos()
        
        bleProcessarRetornos = processarRetornos
        
        debugV("totMsgEnviar=", MensagensBluetooth.filaMensagens.count)
        
        #endif
        
        return
        
    }
    
    private func bleEnviarMensagensIniciais() {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Enviar mensagens iniciais da conexao
        
        MensagensBluetooth.geraMensagensIniciais()
        
        // --- Mensagens de configuracoes
        
        // Configura os fatores de potencia
        
        bleEnviarConfigFatoresPotencia()
        
        // Configura o fator Maximum Color
        
        MensagensBluetooth.geraMensagemConfigFatorMaximumColor(salvar: true, fatorMaximumColor: Settings.fatorMaximumColor)
        
        // Sensor da mascara
        
        MensagensBluetooth.geraMensagemConfiguracao(salvar: true, nome: "SMASC", valor: "\((Settings.sensorMascaraAtivo) ? "S" : "N"):\(Settings.sensorMascaraDifMin)")
        
        // Intervalos
        
        let intervMaxInativDispositivo : Int = (Settings.timeMaxInactivity / 2) // O parametro do dispositivo Ã© de 2 vezes menos do que o app, devido aos feedbacks
        
        MensagensBluetooth.geraMensagemConfiguracao(salvar: true, nome: "INTERV", valor: "\(Settings.intervMaxSemFeedback):\(Settings.intervMaxPausa):\(intervMaxInativDispositivo)")
        
        // Brilho
        
        // var brilho : Int = self.brilho
        
        // Olhos abertos ?
        // Comentado no Android
        //        if (mHabilitarOlhosAbertos && mSessaoOlhosAbertos &&
        //                (mBrilhoMaxOlhosAbertos > 0 && mBrilhoMaxOlhosAbertos < 25)) {
        //            brilho = (int) Math.round(brilho * (mBrilhoMaxOlhosAbertos / 100.f)) // Aplica a reducao do brilho
        //        }
        
        MensagensBluetooth.geraMensagemBrilho(brilho: 100)
        
        // Envia as mensagens
        
        bleEnviarMensagensFila(true)
        
        #endif
        
    }
    
    // Configura os fatores de potenca
    
    public func bleEnviarConfigFatoresPotencia(sessaoOlhosAbertos:Bool = false) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Configura os fatores de potencia
        
        if Settings.habilitarOlhosAbertos && sessaoOlhosAbertos { // Para olhos abertos
            var fatorPotOFechAmarAzulExtra : Int = 0 // Sem leds extras
            if (dispTotalLeds == 8) { // com led amarelo
                fatorPotOFechAmarAzulExtra = Settings.fatorPotOFechAmarelo
            }
            MensagensBluetooth.geraMensagemConfigFatoresPotLeds( salvar: true, brilho: 0, fatorVermelho: Settings.fatorPotOAbertVermelho, fatorVerde: Settings.fatorPotOAbertVerde, fatorAzul: Settings.fatorPotOAbertAzul, fatorAmarelo: fatorPotOFechAmarAzulExtra)
            
        } else { // Para olhos fechados
            
            var fatorPotOFechAmarAzulExtra : Int = 0
            if (dispTotalLeds == 8) { // com led amarelo
                fatorPotOFechAmarAzulExtra = Settings.fatorPotOFechAmarelo
            } else if (dispLedAzExtraCanal) { // Led azul extra no canal
                fatorPotOFechAmarAzulExtra = Settings.fatorPotOFechAzulExtra
            }
            MensagensBluetooth.geraMensagemConfigFatoresPotLeds( salvar: true, brilho: 0, fatorVermelho: Settings.fatorPotOFechVermelho, fatorVerde: Settings.fatorPotOFechVerde, fatorAzul: Settings.fatorPotOFechAzul, fatorAmarelo: fatorPotOFechAmarAzulExtra)
        }
        
        #endif
    }
    
    func btEnviarFeedback() {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Envia feedback a cada segundo
        
        debugV("")
        
        // Se a fila estiver cheia, ignora
        
        if MensagensBluetooth.filaMensagens.count > 0 {  // BtUtil.mBtEnviando) {
            return
        }
        
        // Envia mensagem
        
        bleEnviarMensagem(MensagensBluetooth.MENSAGEM_FEEDBACK, true)
        
        #endif
    }
    
    func bleMensagemOK(_ linha: String) -> Bool {
        
        // Mensagens de retorno OK ou com valores pedidos (ex. Battery)
        
        var ret : Bool = false
        
        if linha.starts(with: MensagensBluetooth.MENSAGEM_OK) {
            ret = true
        } else if linha.starts(with: MensagensBluetooth.MENSAGEM_INICIAL) {
            ret = true
        } else if linha.starts(with: MensagensBluetooth.MENSAGEM_VERSAO) {
            ret = true
        } else if linha.starts(with: MensagensBluetooth.MENSAGEM_ENERGIA) {
            ret = true
        } else if linha.starts(with: MensagensBluetooth.MENSAGEM_CONFIGURAR) {
            ret = true
        } else if linha.starts(with: MensagensBluetooth.MENSAGEM_EXECUTAR) {
            ret = true
        } else if linha.starts(with: MensagensBluetooth.MENSAGEM_FEEDBACK) {
            ret = true
        }
        
        return ret
    }
    
    func bleProcessarMensagemRecebida(_ mensagem: String) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Processa as mensagens de retorno
        
        if mensagem.count < 3 {
            
            debugE("msg invalida (<3):", mensagem)
            
            // TODO: Utilitarios.mostrarToast(getString(R.string.recebida_mensagem_invalida))
            // TODO: mostrarDebug(getString(R.string.debug_resposta_invalida_recebida))
            
            // Aborta processamento (comentado no android)
            //bleAbortarConexao(mensagem: "Recebida uma mensagem BT invalida (cod B8)")
            
            return
            
        }
        
        // Extrai codigo e corpo da mensagem
        
        let codAux:String = mensagem.extSubstring(0, 1)
        let codMsg:Int = Int(codAux) ?? -1
        
        let conteudo:String = mensagem.extSubstring(3)
        
        // Campos delimitados
        
        let retiraCampo: RetiraCampo = RetiraCampo(conteudo, delim:":")
        
        // Zera o timeout
        
        bleTimeout = timeoutBLE
        
        // Processa as mensagens
        
        switch codMsg {
            
        case MensagensBluetooth.CODIGO_OK: // OK
            
            // Recebido OK
            
            break
            
        case MensagensBluetooth.CODIGO_INICIO: // Inicio
            
            // Informacoes - formato OK:TL:n[:LEC]
            
            // Totais de leds do dispositivo
            
            if retiraCampo.getCampo(2) == "TL" {
                
                dispTotalLeds = retiraCampo.getCampoInt(3)
                
                if retiraCampo.getCampo(4) == "LAEC" { // Led azul extra no canal ao inves do amarelo
                    dispLedAzExtraCanal = true
                }
            } else { // Default
                dispTotalLeds = 8
                dispLedAzExtraCanal = false
            }
            
            // Envia as outras mensagens iniciais
            
            bleEnviarMensagensIniciais()
            
        case MensagensBluetooth.CODIGO_VERSAO: // Versao
            
            // Retorno de version
            
            debugV("version recebida =", mensagem)
            
            let posVersao:Int = conteudo.extIndexOf("=")
            if posVersao != -1 {
                versionDevice = conteudo.extSubstring(posVersao + 1)
                debugD("version recebida =", versionDevice)
            }
            
            // Exibe o menu principal
            
            showVCMainMenu()
            
        case MensagensBluetooth.CODIGO_ENERGIA: // Status da energia: USB ou Battery
            
            debugV("Menssagem de energia recebida -> ", conteudo)
            
            showStatusBattery(retiraCampo: retiraCampo)
            
        case MensagensBluetooth.CODIGO_EXECUTAR: // Executar a sessao
            
            // EstÃ¡ na tela do play ?
            
            guard let playVC:PlayViewController = navigationController?.topViewController as? PlayViewController else {
                return
            }
            
            playVC.executarSessaoAVS()
            
        case MensagensBluetooth.CODIGO_STATUS_EXEC: // Status da execucao
            
            if self.emExecucao == false {
                bleAbortarConexao(mensagem: "Executando no dispositivo e nao no app")
                return
            }
            
            if conteudo.count == 0 {
                return
            }
            
            // EstÃ¡ na tela do play ?
            
            guard let playVC:PlayViewController = navigationController?.topViewController as? PlayViewController else {
                return
            }
            
            let nrSegAtual : Int = retiraCampo.getCampoInt(2)
            
            //int nrSubSegAtual = Utilitarios.retirarCampoInt(mensagem, ":", 3)
            
            debugV("Status -> seg: \(nrSegAtual)") // + " subseg:" + nrSubSegAtual)
            
            if nrSegAtual == 1 && // nrSubSegAtual <= 1 &&
                playVC.isReproduzindo == false {
                
                // Ativa timer <<< agora e' via status recebido do inicio da execucao
                
                ativaTimer(ativa: true)
                
                // Inicia o audio <<< agora e' via status recebido do inicio da execucao
                
                playVC.mp3Reproduzir()
                
            } else if nrSegAtual == playVC.nrSegmentoAtual {
                
                // Nao faz nada
                
            } else if nrSegAtual == (playVC.nrSegmentoAtual + 1) { // O dispositivo jÃ¡ foi para o proximo segmento
                
                // Proximo segmento
                
                playVC.setNrSegmentoAtual(segmento: nrSegAtual)
                
                playVC.executarSegmentoAVS()
                
            } else { // Invalido
                
                debugE("Nr. Segmento invÃ¡lido no dispositivo: \(nrSegAtual)")
                // btAbortarConexao("Nr. Segmento invÃ¡lido no dispositivo")
                return
                
            }
            
            // Depuracao // TODO: fazer para o iOS ?
            
            // exibirDebugAtivLeds()
            
        case MensagensBluetooth.CODIGO_DEBUG: // Debug
            
            debugV("Msg debug receb.: \(conteudo)")
            
        case MensagensBluetooth.CODIGO_DEBUG_ECHO: // Debug - echo
            
            break
            
        case MensagensBluetooth.CODIGO_FEEDBACK: // Feedback
            
            // Status da execucao
            
            let status : String = retiraCampo.getCampo(1)
            let emExecucao : Bool = (status == "S")
            
            // Verifica status
            
            if self.emExecucao == false && emExecucao == true {
                bleAbortarConexao(mensagem: "Executando no dispositivo e nao no app")
            } else if self.emExecucao == true && emExecucao == false {
                bleAbortarConexao(mensagem: "Executando no app e nao no dispositivo")
            }
            
        case MensagensBluetooth.CODIGO_FB_SENSOR_MASCARA: // Feedback do sensor da mascara
            
            //TODO verifSensorMascara(mensagem)
            break
            
        case MensagensBluetooth.CODIGO_FB_SENSOR_EXTERNO: // Feedback do sensor externo
            
            //TODO verifSensorExterno(mensagem)
            break
            
        case MensagensBluetooth.CODIGO_STANDBY: // Entrou em standby
            
            bleAbortarConexao(mensagem: "O EspApp foi desligado")
            
            //TODO: Utilitarios.mostrarToast(getString(R.string.o_relax_mind_foi_desligado))
            
        case MensagensBluetooth.CODIGO_FIM_SESSAO: // Finaliza a sessao
            
            // EstÃ¡ na tela do play ?
            
            guard let playVC:PlayViewController = navigationController?.topViewController as? PlayViewController else {
                return
            }
            
            playVC.finalizarSessaoAVS(modo: "Termino")
            
        default: // Erro ou codigo desconhecido
            
            debugE("abortar - msg invalida", mensagem)
            
            // Comentado no Android
            //            Utilitarios.mostrarToast(
            //                    "Resposta OK nao recebida. Abortando o processo", true)
            //
            //            mostrarDebug("--Resposta invalida recebida. Abortando o processo")
            //
            //            btAbortarConexao("Recebida uma mensagem BT invalida (cod B9)")
            
        }
        
        #endif
    }
    
    func bleNameDeviceConnected () -> String {
        
        // Retorna o nome do dispositivo conectado
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        return (ble.connected) ? " Conectado a \(ble.peripheralConnected?.name ?? "")" : " NÃ£o conectado ao EspApp"
        #else // Simulador
        
        return " Conectado a simulador"
        
        #endif
    }
    
    // BLE delegates
    
    func bleDidUpdateState(_ state: BLECentralManagerState) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Verifica o estado
        
        if state == BLECentralManagerState.poweredOn {
            
            // Inicia a procura
            
            bleProcurarDispositivoLigado()
            
        } else {
            
            //If Bluetooth is off, display a UI alert message saying "Bluetooth is not enable" and "Make sure that your bluetooth is turned on"
            
            debugW("Bluetooth desabilitado")
            
            bleAbortarConexao(mensagem: "Favor ligar o Bluetooth")
            
            // EstÃ¡ na tela da conexao ?
            
            if let conectandoVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
                Alerta.alerta("Favor ligar o Bluetooth", titulo:"Bluetooth nÃ£o estÃ¡ ligado", viewController: conectandoVC)
            }
            
        }
        
        #endif
    }
    
    func bleDidTimeoutScan() {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Nao localizado nenhum EspApp Ligado
        
        bleAbortarConexao(mensagem: "NÃ£o foi possÃ­vel conectar ao EspApp")
        
        #endif
    }
    
    func bleDidConnectingToPeripheral(_ name: String) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Conectando
        
        // EstÃ¡ na tela da conexao ?
        
        if let conectandoVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
            conectandoVC.labelMensagemConectando.text = "Localizado: \(name))"
        }
        
        #endif
    }
    
    func bleDidConnectToPeripheral(_ name: String) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Conexao com sucesso (apos descobertas)
        
        // EstÃ¡ na tela da conexao ?
        
        if let conectandoVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
            conectandoVC.labelMensagemConectando.text = "Conectado a \(name)"
        }
        
        // Conexao bem sucedida
        
        bleConectou()
        
        #endif
        
    }
    
    func bleDidReceiveData(data: String) {
    }
    
    func bleDidReceiveLine(line: String) {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Recebeu uma linha do dispositivo EspApp
        
        //        if debugV() {
        //            debugV("linha", line)
        //        }
        
        // Recebeu dados do Bluetooth
        
        // Le linha a linha, para o processamento desta
        
        bleNrMsgReceb+=1
        
        if bleAguardandoOK == false {
            //            exibirStatusBle(ativo: false)
            mostrarMensagemStatus("")
        }
        
        //        var faltam:Int = (bleNrMsgEnviadas - bleNrMsgReceb)
        //
        //        if faltam <= 0 {
        //            mostrarMensagemStatus("")
        //        } else {
        //            mostrarMensagemStatus("Aguardando resposta do EspApp (\(faltam) ...")
        //        }
        
        //TODO: mostrarDebug("BT: <- " + linha + "")
        
        // Desativa verificacao de timeout
        
        bleVerifTimeout = false
        
        // Restarta o tempo do feedback
        
        tempoFeedback = 0
        
        // Processa a mensagem
        
        if line.starts(with: MensagensBluetooth.MENSAGEM_ERRO) {
            
            // Ocorreu erro
            
            debugE("ocorreu erro: \(line)")
            
            //TODO: Utilitarios.mostrarToast(getString(R.string.ocorreu_um_erro_no_relaxmind) + linha, true)
            
            bleAbortarConexao(mensagem: "Ocorreu um exceÃ§Ã£o no EspApp: " + line)
            
            return
            
        } else if bleMensagemOK(line) { // Mensagens de retorno OK ou com valores pedidos (ex. Battery)
            
            // Recebido OK
            
            if bleProcessarRetornos == true { // Processar as mensagens recebidas
                
                // TODO: ??
                //                if (mBtStatusAtivo == true) {
                //                    btMostrarStatus("", mDrawableIconBTInativo)
                //                    mBtStatusAtivo = false
                //                }
                //
                bleNrMsgOKReceb+=1
                
                if (bleAguardandoOK) {
                    
                    let faltam: Int = (bleNrMsgEnviadas - bleNrMsgOKReceb)
                    
                    if (faltam <= 0) {
                        bleAguardandoOK = false
                        //                        exibirStatusBle(ativo: false)
                        mostrarMensagemStatus("")
                    } else {
                        mostrarMensagemStatus("Aguardando resposta do EspApp (\(faltam)) ...")
                    }
                }
                
                debugV("Mensagens Recebidas = \(bleNrMsgReceb) OK = \(bleNrMsgOKReceb)")
            }
        }
        
        // Processa a mensagem recebida
        
        bleProcessarMensagemRecebida(line)
        
        #endif
        
    }
    
    func bleDidDisconnectFromPeripheral() {
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        // Desconectou
        
        bleAbortarConexao(mensagem: "O EspApp foi desconectado (cod B5)")
        
        #endif
    }
    
    /////// Utilitarias
    
    func mostrarMensagemStatus(_ mensagem:String) {
        
        // Exibe uma mensagem no rodape
        
        var label:UILabel!
        
        if let conexaoVC = navigationController?.topViewController as? ConnectingViewController {
            label = conexaoVC.labelMensagemConectando
        } else if let menuPrincipalVC = navigationController?.topViewController as? MainMenuViewController {
            label = menuPrincipalVC.labelStatus
        } else if let menuBaixarVC = navigationController?.topViewController as? MenuBaixarViewController {
            label = menuBaixarVC.labelStatus
        } else if let menuPacotesAVSVC = navigationController?.topViewController as? MenuPacotesAVSViewController {
            label = menuPacotesAVSVC.labelStatus
        } else if let playVC = navigationController?.topViewController as? PlayViewController {
            label = playVC.labelStatus
        } else if let playInicioVC = navigationController?.topViewController as? PlayInicioViewController {
            label = playInicioVC.labelStatus
        } else if let playFimVC = navigationController?.topViewController as? PlayFimViewController {
            label = playFimVC.labelStatus
        }
        
        if label != nil {
            
            // Atualiza a UI
            
            DispatchQueue.main.async {
                
                label.text = mensagem
            }
            
        } else {
            
            debugV(mensagem)
            
        }
    }
    
    public func procuraPacoteAVS(codigoPacote : String) -> PacoteAVS_v1? {
        
        // Procura o pacote da sessao
        
        for pacote : PacoteAVS_v1 in relaxMind.pacotesAVS {
            
            if pacote.codigo != nil &&
                pacote.codigo == codigoPacote &&
                pacote.tipoPacoteAVS != "Recomendadas" { // Ignora as recomendadas
                return pacote
            }
        }
        
        return nil
    }
    
    public func procuraSessaoPacoteAVS(codigoPacote : String, codigoSessao:String) -> SessaoPacoteAVS_v1? {
        
        // Procura a sessao do pacote
        
        if let pacote : PacoteAVS_v1 = procuraPacoteAVS(codigoPacote: codigoPacote) {
            
            for sessaoPacote : SessaoPacoteAVS_v1 in pacote.sessoesPacoteAVS {
                
                if sessaoPacote.codigo != nil &&
                    sessaoPacote.codigo == codigoSessao {
                    return sessaoPacote
                }
            }
        }
        
        return nil
    }
    
    private func inicializar () {
        
        // Inicializar
        
        // Debug - seta nivel para depuracoes
        
        debugSetLevel(.verbose)
        
        debugV("Inicializando ...")
        
        // Diretorio dos pacotes AVS
        
        self.diretorioRelaxMind = Arquivo.diretorioDocumento().path // appendingPathComponent("Files", isDirectory: true).path
        
        self.diretorioPacotesAVS = self.diretorioRelaxMind + "/PacotesAVS"
        
        // Cria os diretorios se nao existirem
        
        if Arquivo.existe(path: self.diretorioRelaxMind) == false {
            if Arquivo.criarDiretorio(path: self.diretorioRelaxMind, subDiretorios: true) == false {
                fatalError("NÃ£o foi possÃ­vel criar o diretorio do EspApp")
            }
        }
        
        if Arquivo.existe(path: self.diretorioPacotesAVS) == false {
            if Arquivo.criarDiretorio(path: self.diretorioPacotesAVS, subDiretorios: false) == false {
                fatalError("NÃ£o foi possÃ­vel criar o diretorio do EspApp / PacotesAVS")
            }
        }
        
        //        // Debug - deixar comentado
        //        let files = FileManager.default.enumerator(atPath: self.diretorioPacotesAVS)
        //        while let file = files?.nextObject() {
        //            debugV(file)
        //        }
        //
        // Le os dados do objeto EspApp
        
        lerRelaxMind()
        
        // BLE
        
        #if !targetEnvironment(simulator) // Dispositivo real
        
        ble.delegate = self
        ble.showDebug(.debug)
        // ble.showDebug(.verbose)
        
        #else // Simulador
        
        self.versionDevice = "Simul."
        
        #endif
        
        // Inicializa variaveis
        
        inicializarVariaveis()
        
        // Fim
        
        debugV("Inicializado")
        
    }
    
    // Salvar o objeto EspApp
    
    func salvarRelaxMind() {
        
        self.relaxMind.ordemExibicao = "OK"
        
        let urlArquivo = Arquivo.diretorioDocumento().appendingPathComponent("RelaxMind.bin")
        
        let salvou = NSKeyedArchiver.archiveRootObject(self.relaxMind, toFile: urlArquivo.path)
        
        if salvou == false {
            
            fatalError("salvarRelaxMind: erro ao salvar o arquivo")
        } else {
            
            debugV("arquivo salvo")
        }
    }
    
    // Ler o objeto EspApp
    
    func lerRelaxMind() {
        
        let urlArquivo = Arquivo.diretorioDocumento().appendingPathComponent("RelaxMind.bin")
        
        if Arquivo.existe(url: urlArquivo) {
            
            if let aux: RelaxMind_v1 = NSKeyedUnarchiver.unarchiveObject(withFile: urlArquivo.path) as? RelaxMind_v1 {
                
                self.relaxMind = aux
                
                debugV("arquivo lido")
                
                // Debug - deixar comentado
                
                //                for pacote:PacoteAVS_v1 in self.relaxMind.pacotesAVS {
                //
                //                    debugV("pacote:. (pacote.nome) tipo: \(pacote.tipoPacoteAVS)sessoes: \(pacote.sessoesPacoteAVS.count)")
                //                    for sessao in pacote.sessoesPacoteAVS {
                //                        var nome:String = ""
                //                        if let sessaoAVS = sessao.sessaoAVS {
                //                            nome = sessaoAVS.nome
                //                        }
                //                        debugV("Sessao: \(sessao.codigo) nome: \(nome)")
                //                    }
                //                }
                //
            } else {
                fatalError("lerRelaxMind: erro ao abrir o arquivo")
            }
        }
    }
    
}
