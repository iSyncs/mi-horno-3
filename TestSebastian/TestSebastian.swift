//
//  TestSebastian.swift
//  TestSebastian
//
//  Sebastián Sanchez
//
 
import Testing
import Foundation
@testable import Mi_Horno_3
 
@MainActor
struct TestSebastian {
    
    // ─────────────────────────────────────────────
    // MARK: - Guía Sensorial
    // ─────────────────────────────────────────────
    
    /// Verifica que sendMessage() agrega el mensaje del usuario
    /// al historial y limpia inputText automáticamente.
    @Test func sensory_sendMessage_appendsUserMessageAndClearsInput() async throws {
        let vm = SensoryViewModel()
        vm.inputText = "¿Hay mucho ruido en la Sala del Alto Horno?"
        
        vm.sendMessage()
        
        #expect(vm.messages.count == 1)
        #expect(vm.messages.first?.role == .user)
        #expect(vm.messages.first?.text == "¿Hay mucho ruido en la Sala del Alto Horno?")
        #expect(vm.inputText.isEmpty)
    }
    
    /// Verifica que clearChat() elimina todos los mensajes
    /// y que canSend bloquea el envío con texto vacío.
    @Test func sensory_clearChat_and_canSend_validation() async throws {
        let vm = SensoryViewModel()
        
        // Agregar mensajes directamente sin pasar por sendMessage()
        // para evitar dependencia del comportamiento asíncrono
        vm.messages.append(SensoryMessage(role: .user, text: "Primera pregunta", tip: nil, level: nil))
        vm.messages.append(SensoryMessage(role: .user, text: "Segunda pregunta", tip: nil, level: nil))
        
        #expect(vm.messages.count == 2)
        
        vm.clearChat()
        
        #expect(vm.messages.isEmpty)
        
        // canSend requiere texto no vacío y que no esté cargando
        vm.inputText = ""
        vm.isLoading = false
        #expect(vm.canSend == false)
        
        vm.inputText = "¿Qué salas tienen luces intermitentes?"
        #expect(vm.canSend == true)
    }
    
    // ─────────────────────────────────────────────
    // MARK: - Wrapped
    // ─────────────────────────────────────────────
    
    /// Verifica que WrappedData calcula correctamente
    /// el porcentaje de precisión y el texto de progreso.
    @Test func wrapped_data_accuracy_and_progressText() async throws {
        let nickname = VisitorNickname(name: "Test", icon: "star", description: "Desc")
        
        let data = WrappedData(
            answersCount: 8,
            correctCount: 6,
            unlockedMedals: 3,
            totalMedals: 6,
            nickname: nickname
        )
        
        #expect(data.accuracy == 75)
        #expect(data.progressText == "8/114")
        
        // Caso borde: sin respuestas no debe crashear
        let emptyData = WrappedData(
            answersCount: 0,
            correctCount: 0,
            unlockedMedals: 0,
            totalMedals: 6,
            nickname: nickname
        )
        #expect(emptyData.accuracy == 0)
    }
    
    /// Verifica que la navegación entre tarjetas respeta
    /// los límites y avanza/retrocede correctamente.
    @Test func wrapped_navigation_next_and_previous() async throws {
        let vm = WrappedViewModel(
            answersCount: 5,
            correctCount: 3,
            unlockedMedals: 2,
            totalMedals: 6,
            badges: []
        )
        let lm = LocalizationManager.shared
        vm.buildCards(lm: lm)
        
        #expect(vm.currentIndex == 0)
        #expect(vm.isFirstCard == true)
        #expect(vm.isLastCard == false)
        
        let totalCards = vm.cards.count
        for _ in 0..<(totalCards - 1) { vm.next() }
        
        #expect(vm.currentIndex == totalCards - 1)
        #expect(vm.isLastCard == true)
        
        // next() en la última tarjeta no debe avanzar
        vm.next()
        #expect(vm.currentIndex == totalCards - 1)
        
        // previous() debe retroceder
        vm.previous()
        #expect(vm.currentIndex == totalCards - 2)
    }
    
    // ─────────────────────────────────────────────
    // MARK: - Encuesta
    // ─────────────────────────────────────────────
    
    @Test func survey_submit_marksCompletedAndUnlocksBadge() async throws {
        // Limpiar las keys correctas (con userId)
        UserDefaults.standard.removeObject(forKey: SurveyViewModel.currentUserSurveyCompletedKey)
        UserDefaults.standard.removeObject(forKey: SurveyViewModel.currentUserUnlockedBadgesKey)
        
        let vm = SurveyViewModel()
        
        for question in vm.questions {
            vm.answers[question.id] = question.options.first ?? "Opción A"
        }
        
        vm.submit()
        
        #expect(vm.submitted == true)
        
        // Leer de la key correcta (con userId)
        let badges = UserDefaults.standard.array(forKey: SurveyViewModel.currentUserUnlockedBadgesKey) as? [String] ?? []
        #expect(badges.contains("encuesta"))
        
        // Limpieza con las keys correctas
        UserDefaults.standard.removeObject(forKey: SurveyViewModel.currentUserSurveyCompletedKey)
        UserDefaults.standard.removeObject(forKey: SurveyViewModel.currentUserUnlockedBadgesKey)
        UserDefaults.standard.removeObject(forKey: SurveyViewModel.kPendingSubmission)
    }
    
    @Test func survey_navigation_select_advances_and_next_respects_bounds() async throws {
        let vm = SurveyViewModel()
        
        #expect(vm.currentIndex == 0)
        #expect(vm.questions[0].hasFollowUp == false)
        
        vm.select(vm.questions[0].options[0])
        #expect(vm.answers[0] != nil)
        
        // Ceder el actor con Task.yield para que el Task interno de select() pueda correr,
        // luego esperar el delay de 320ms + margen
        await Task.yield()
        try await Task.sleep(nanoseconds: 450_000_000)
        await Task.yield()
        
        #expect(vm.currentIndex == 1)
        
        vm.currentIndex = vm.questions.count - 1
        #expect(vm.isLast == true)
        
        let lastIndex = vm.currentIndex
        vm.next()
        #expect(vm.currentIndex == lastIndex)
    }
    
}
