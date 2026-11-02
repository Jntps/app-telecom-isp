# Configuração Android necessária

O ZIP contém apenas o código `lib/`, os testes e os recursos visuais.
Não substitua toda a pasta `android/` do seu projeto.

## 1. AndroidManifest.xml

No arquivo `android/app/src/main/AndroidManifest.xml`, dentro de
`<manifest>` e **antes** de `<application>`, confira estas permissões:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

A localização é solicitada apenas quando a Home precisa ordenar os chamados.
Não é necessário liberar localização em segundo plano.

O `image_picker` usa os recursos do Android e normalmente não exige
configuração adicional para abrir a câmera ou a galeria.

## 2. SDK e AndroidX

A documentação atual do `geolocator` recomenda `compileSdk 35` ou superior.

Se o projeto usa `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 35
}
```

Se usa `android/app/build.gradle` (Groovy):

```groovy
android {
    compileSdkVersion 35
}
```

Confira `android/gradle.properties`:

```properties
android.useAndroidX=true
android.enableJetifier=true
```

Não copie cegamente os exemplos sobre o arquivo inteiro: preserve as
configurações do Flutter, namespace e applicationId existentes.

## 3. Recompilar de verdade

Ao instalar plugins novos, pare o emulador em execução pelo terminal e rode:

```powershell
flutter clean
flutter pub get
flutter run
```

Se ainda encontrar `10.0.2.2`, verifique a pasta atual do terminal com
`Get-Location`. Você precisa executar a pasta que contém o novo `lib/data/`.

## 4. Permissões no emulador

Aceite a solicitação de localização. Caso o GPS do emulador não esteja ativo,
a Home exibe "GPS indisponível" e mantém os chamados listados.
