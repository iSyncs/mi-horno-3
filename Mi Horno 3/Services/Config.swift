// Config.swift
// ⚠️ Agrega este archivo al .gitignore para no subir tu IP al repo
// .gitignore: Mi\ Horno\ 3/Config.swift

import Foundation

enum Config {
    static let baseURL = "https://mi-horno-3-git-testing-joel-tellezs-projects.vercel.app/api/v1"
    static let serverRootURL = baseURL.replacingOccurrences(of: "/api/v1", with: "")
}
