// Código JavaScript para el plugin de Figma GPT

// ===== FUNCIONES AUXILIARES =====
async function loadFonts() {
    console.log("📚 Cargando fuentes...");
    await figma.loadFontAsync({ family: "Inter", style: "Regular" });
    await figma.loadFontAsync({ family: "Inter", style: "Bold" });
    console.log("✅ Fuentes cargadas");
}

function clearPage() {
    console.log("🧹 Limpiando página...");
    const existingNodes = figma.currentPage.children.slice();
    for (const node of existingNodes) {
        node.remove();
    }
    console.log("✅ Página limpiada");
}

function createScreenLabel(text, x, y) {
    const label = figma.createText();
    label.characters = text;
    label.fontSize = 24;
    label.fontName = { family: "Inter", style: "Bold" };
    label.x = x;
    label.y = y;
    label.fills = [{ type: "SOLID", color: { r: 0.2, g: 0.2, b: 0.2 } }];
    figma.currentPage.appendChild(label);
    return label;
}

function createStatusBar(frame, x, y) {
    // Hora
    const time = figma.createText();
    time.characters = "9:41";
    time.fontSize = 15;
    time.fontName = { family: "Inter", style: "Bold" };
    time.x = x;
    time.y = y;
    time.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
    frame.appendChild(time);

    // Batería
    const battery = figma.createRectangle();
    battery.resize(24, 12);
    battery.x = x + 336;
    battery.y = y + 3;
    battery.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
    battery.cornerRadius = 2;
    frame.appendChild(battery);

    // Cámara
    const camera = figma.createEllipse();
    camera.resize(12, 12);
    camera.x = x + 174;
    camera.y = y + 5;
    camera.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
    frame.appendChild(camera);
}

function createHomeIndicator(frame, x, y) {
    const indicator = figma.createRectangle();
    indicator.resize(134, 5);
    indicator.x = x;
    indicator.y = y;
    indicator.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
    indicator.cornerRadius = 2.5;
    frame.appendChild(indicator);
}

function createInputField(frame, x, y, placeholder) {
    const field = figma.createRectangle();
    field.resize(335, 56);
    field.x = x;
    field.y = y;
    field.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    field.cornerRadius = 8;
    field.strokes = [{ type: "SOLID", color: { r: 0.8, g: 0.8, b: 0.8 } }];
    field.strokeWeight = 1;
    frame.appendChild(field);

    const hint = figma.createText();
    hint.characters = placeholder;
    hint.fontSize = 14;
    hint.fontName = { family: "Inter", style: "Regular" };
    hint.x = x + 17.5;
    hint.y = y + 15;
    hint.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
    frame.appendChild(hint);

    return field;
}

function createButton(frame, x, y, text, width = 335, height = 48) {
    const button = figma.createRectangle();
    button.resize(width, height);
    button.x = x;
    button.y = y;
    button.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    button.cornerRadius = 8;
    frame.appendChild(button);

    const buttonText = figma.createText();
    buttonText.characters = text;
    buttonText.fontSize = 16;
    buttonText.fontName = { family: "Inter", style: "Regular" };
    buttonText.x = x + (width - 100) / 2;
    buttonText.y = y + (height - 20) / 2;
    buttonText.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    frame.appendChild(buttonText);

    return button;
}

function createRoleSelector(frame, x, y) {
    const selector = figma.createRectangle();
    selector.resize(335, 40);
    selector.x = x;
    selector.y = y;
    selector.fills = [{ type: "SOLID", color: { r: 0.95, g: 0.95, b: 0.95 } }];
    selector.cornerRadius = 8;
    frame.appendChild(selector);

    const roles = ["dev", "customer", "restaurant"];
    roles.forEach((role, index) => {
        const roleButton = figma.createText();
        roleButton.characters = role;
        roleButton.fontSize = 16;
        roleButton.fontName = { family: "Inter", style: "Regular" };
        roleButton.x = x + 17.5 + (index * 100);
        roleButton.y = y + 10;
        roleButton.fills = [{
            type: "SOLID",
            color: index === 1 ? { r: 0.1, g: 0.6, b: 0.8 } : { r: 0.6, g: 0.6, b: 0.6 }
        }];
        frame.appendChild(roleButton);
    });
}

function createArrow(fromX, fromY, toX, toY) {
    const arrow = figma.createLine();
    arrow.resize(Math.abs(toX - fromX), 0);
    arrow.x = fromX;
    arrow.y = fromY;
    arrow.strokes = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    arrow.strokeWeight = 3;
    figma.currentPage.appendChild(arrow);

    const arrowHead = figma.createPolygon();
    arrowHead.resize(12, 12);
    arrowHead.x = toX - 6;
    arrowHead.y = toY - 6;
    arrowHead.rotation = 0;
    arrowHead.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    figma.currentPage.appendChild(arrowHead);
}

// ===== CREACIÓN DE PANTALLAS =====
function createLoginScreen() {
    console.log("📱 Creando pantalla de login...");

    const frame = figma.createFrame();
    frame.resize(390, 844);
    frame.x = 100;
    frame.y = 100;
    frame.name = "Pantalla Login";
    frame.fills = [{ type: "SOLID", color: { r: 0.98, g: 0.98, b: 0.98 } }];
    frame.cornerRadius = 20;
    figma.currentPage.appendChild(frame);

    createScreenLabel("Login Screen", 225, 70);
    createStatusBar(frame, 20, 15);

    // Título
    const title = figma.createText();
    title.characters = "The Final Burger";
    title.fontSize = 32;
    title.fontName = { family: "Inter", style: "Bold" };
    title.x = 85;
    title.y = 120;
    title.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
    frame.appendChild(title);

    // Campos de entrada
    createInputField(frame, 27.5, 220, "Email");
    createInputField(frame, 27.5, 300, "Password");

    // Icono de visibilidad
    const eyeIcon = figma.createEllipse();
    eyeIcon.resize(20, 16);
    eyeIcon.x = 330;
    eyeIcon.y = 314;
    eyeIcon.fills = [{ type: "SOLID", color: { r: 0.6, g: 0.6, b: 0.6 } }];
    frame.appendChild(eyeIcon);

    // Selector de roles
    createRoleSelector(frame, 27.5, 380);

    // Botón de login
    createButton(frame, 27.5, 450, "Iniciar sesion");

    // Enlaces
    const registerLink = figma.createText();
    registerLink.characters = "No tienes cuenta? Registrate";
    registerLink.fontSize = 14;
    registerLink.fontName = { family: "Inter", style: "Regular" };
    registerLink.x = 100;
    registerLink.y = 530;
    registerLink.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    frame.appendChild(registerLink);

    const guestLink = figma.createText();
    guestLink.characters = "Continuar como invitado";
    guestLink.fontSize = 14;
    guestLink.fontName = { family: "Inter", style: "Regular" };
    guestLink.x = 110;
    guestLink.y = 560;
    guestLink.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    frame.appendChild(guestLink);

    console.log("✅ Pantalla de login creada");
    return frame;
}

function createRegisterScreen() {
    console.log("📱 Creando pantalla de registro...");

    const frame = figma.createFrame();
    frame.resize(390, 844);
    frame.x = 600;
    frame.y = 100;
    frame.name = "Pantalla Registro";
    frame.fills = [{ type: "SOLID", color: { r: 0.98, g: 0.98, b: 0.98 } }];
    frame.cornerRadius = 20;
    figma.currentPage.appendChild(frame);

    createScreenLabel("Register Screen", 725, 70);
    createStatusBar(frame, 20, 15);

    // Título
    const title = figma.createText();
    title.characters = "The Final Burger";
    title.fontSize = 32;
    title.fontName = { family: "Inter", style: "Bold" };
    title.x = 85;
    title.y = 120;
    title.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
    frame.appendChild(title);

    // Campos de entrada
    createInputField(frame, 27.5, 200, "Nombre completo");
    createInputField(frame, 27.5, 280, "Email");
    createInputField(frame, 27.5, 360, "Password");
    createInputField(frame, 27.5, 440, "Confirm password");

    // Selector de roles
    createRoleSelector(frame, 27.5, 520);

    // Botón de registro
    createButton(frame, 27.5, 590, "Registrarse");

    // Enlace de login
    const loginLink = figma.createText();
    loginLink.characters = "Ya tienes cuenta? Inicia sesion";
    loginLink.fontSize = 14;
    loginLink.fontName = { family: "Inter", style: "Regular" };
    loginLink.x = 100;
    loginLink.y = 660;
    loginLink.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    frame.appendChild(loginLink);

    console.log("✅ Pantalla de registro creada");
    return frame;
}

async function createHomeCustomerScreen() {
    console.log("🏠 Creando pantalla Home Customer...");

    const frame = figma.createFrame();
    frame.resize(390, 844);
    frame.x = 1100;
    frame.y = 100;
    frame.name = "Explorar";
    frame.fills = [{ type: "SOLID", color: { r: 0.98, g: 0.98, b: 0.98 } }];
    frame.cornerRadius = 20;
    figma.currentPage.appendChild(frame);

    createScreenLabel("Explorar", 1225, 70);
    createStatusBar(frame, 20, 15);

    // Barra de búsqueda (como en Google Maps real)
    const searchBar = figma.createRectangle();
    searchBar.resize(350, 45);
    searchBar.x = 20;
    searchBar.y = 80;
    searchBar.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    searchBar.cornerRadius = 25;
    searchBar.strokes = [{ type: "SOLID", color: { r: 0.9, g: 0.9, b: 0.9 } }];
    searchBar.strokeWeight = 1;
    frame.appendChild(searchBar);

    // Icono de lupa en la barra de búsqueda
    const searchIcon = figma.createEllipse();
    searchIcon.resize(16, 16);
    searchIcon.x = 35;
    searchIcon.y = 96;
    searchIcon.fills = [{ type: "SOLID", color: { r: 0.6, g: 0.6, b: 0.6 } }];
    frame.appendChild(searchIcon);

    // Texto de búsqueda
    const searchText = figma.createText();
    searchText.characters = "Buscar aquí";
    searchText.fontSize = 16;
    searchText.fontName = { family: "Inter", style: "Regular" };
    searchText.x = 60;
    searchText.y = 95;
    searchText.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
    frame.appendChild(searchText);

    // Sugerencia de búsqueda
    const searchSuggestion = figma.createRectangle();
    searchSuggestion.resize(350, 40);
    searchSuggestion.x = 20;
    searchSuggestion.y = 130;
    searchSuggestion.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    searchSuggestion.cornerRadius = 20;
    searchSuggestion.strokes = [{ type: "SOLID", color: { r: 0.9, g: 0.9, b: 0.9 } }];
    searchSuggestion.strokeWeight = 1;
    frame.appendChild(searchSuggestion);

    const suggestionText = figma.createText();
    suggestionText.characters = "Buscando hamburgueserías cercanas...";
    suggestionText.fontSize = 14;
    suggestionText.fontName = { family: "Inter", style: "Regular" };
    suggestionText.x = 35;
    suggestionText.y = 142;
    suggestionText.fills = [{ type: "SOLID", color: { r: 0.3, g: 0.3, b: 0.3 } }];
    frame.appendChild(suggestionText);

    // Mapa con imagen real
    const mapContainer = figma.createRectangle();
    mapContainer.resize(390, 600);
    mapContainer.x = 0;
    mapContainer.y = 60;
    mapContainer.fills = [{ type: "SOLID", color: { r: 0.95, g: 0.97, b: 1 } }];
    frame.appendChild(mapContainer);

    // Cargar imagen de mapa real de Google Maps
    try {
        // Usar una imagen real de Google Maps (Cupertino, CA)
        const mapImage = await figma.createImage(
            "https://maps.googleapis.com/maps/api/staticmap?center=Cupertino,CA&zoom=14&size=390x600&maptype=roadmap&key=DEMO_KEY&style=feature:all|element:labels|visibility:on&style=feature:road|element:geometry|color:0xffffff&style=feature:landscape|element:geometry|color:0xf5f5f5"
        );

        // Si la imagen se carga correctamente, aplicarla al contenedor
        mapContainer.fills = [{
            type: "IMAGE",
            imageHash: mapImage.hash,
            scaleMode: "FILL"
        }];

        console.log("✅ Imagen de Google Maps cargada exitosamente");
    } catch (error) {
        console.log("⚠️ No se pudo cargar la imagen de Google Maps, usando imagen alternativa");

        // Intentar con una imagen alternativa de mapa real
        try {
            const alternativeMapImage = await figma.createImage(
                "https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?w=390&h=600&fit=crop&crop=center"
            );

            mapContainer.fills = [{
                type: "IMAGE",
                imageHash: alternativeMapImage.hash,
                scaleMode: "FILL"
            }];

            console.log("✅ Imagen alternativa de mapa cargada");
        } catch (secondError) {
            console.log("⚠️ Usando mapa simulado como fallback");
            // Mantener el mapa simulado si todo falla
        }
    }

    // Calles principales (horizontales)
    for (let i = 0; i < 4; i++) {
        const street = figma.createRectangle();
        street.resize(390, 3);
        street.x = 0;
        street.y = 80 + (i * 120);
        street.fills = [{ type: "SOLID", color: { r: 0.8, g: 0.8, b: 0.8 } }];
        frame.appendChild(street);
    }

    // Calles secundarias (verticales)
    for (let i = 0; i < 3; i++) {
        const street = figma.createRectangle();
        street.resize(3, 600);
        street.x = 130 + (i * 130);
        street.y = 60;
        street.fills = [{ type: "SOLID", color: { r: 0.8, g: 0.8, b: 0.8 } }];
        frame.appendChild(street);
    }

    // Edificios/parques (rectángulos verdes)
    const buildings = [
        { x: 20, y: 100, w: 80, h: 60, color: { r: 0.7, g: 0.9, b: 0.7 } },
        { x: 290, y: 100, w: 80, h: 60, color: { r: 0.7, g: 0.9, b: 0.7 } },
        { x: 20, y: 220, w: 80, h: 60, color: { r: 0.8, g: 0.8, b: 0.9 } },
        { x: 290, y: 220, w: 80, h: 60, color: { r: 0.8, g: 0.8, b: 0.9 } },
        { x: 20, y: 340, w: 80, h: 60, color: { r: 0.9, g: 0.8, b: 0.8 } },
        { x: 290, y: 340, w: 80, h: 60, color: { r: 0.9, g: 0.8, b: 0.8 } },
        { x: 20, y: 460, w: 80, h: 60, color: { r: 0.8, g: 0.9, b: 0.8 } },
        { x: 290, y: 460, w: 80, h: 60, color: { r: 0.8, g: 0.9, b: 0.8 } }
    ];

    buildings.forEach(building => {
        const buildingRect = figma.createRectangle();
        buildingRect.resize(building.w, building.h);
        buildingRect.x = building.x;
        buildingRect.y = building.y;
        buildingRect.fills = [{ type: "SOLID", color: building.color }];
        buildingRect.cornerRadius = 4;
        frame.appendChild(buildingRect);
    });

    // Restaurantes (puntos rojos con iconos)
    const restaurants = [
        { x: 150, y: 130, name: "Burger Palace" },
        { x: 280, y: 250, name: "The Burger House" },
        { x: 120, y: 370, name: "Burger Express" }
    ];

    restaurants.forEach(restaurant => {
        // Punto del restaurante
        const restaurantPoint = figma.createEllipse();
        restaurantPoint.resize(12, 12);
        restaurantPoint.x = restaurant.x;
        restaurantPoint.y = restaurant.y;
        restaurantPoint.fills = [{ type: "SOLID", color: { r: 0.9, g: 0.3, b: 0.3 } }];
        frame.appendChild(restaurantPoint);

        // Nombre del restaurante
        const restaurantName = figma.createText();
        restaurantName.characters = restaurant.name;
        restaurantName.fontSize = 10;
        restaurantName.fontName = { family: "Inter", style: "Regular" };
        restaurantName.x = restaurant.x - 30;
        restaurantName.y = restaurant.y + 15;
        restaurantName.fills = [{ type: "SOLID", color: { r: 0.3, g: 0.3, b: 0.3 } }];
        frame.appendChild(restaurantName);
    });

    // Marcador de ubicación actual (más prominente)
    const locationMarker = figma.createEllipse();
    locationMarker.resize(24, 24);
    locationMarker.x = 183;
    locationMarker.y = 348;
    locationMarker.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    locationMarker.strokes = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    locationMarker.strokeWeight = 3;
    frame.appendChild(locationMarker);

    // Círculo interior del marcador
    const innerCircle = figma.createEllipse();
    innerCircle.resize(12, 12);
    innerCircle.x = 189;
    innerCircle.y = 354;
    innerCircle.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    frame.appendChild(innerCircle);

    // Botón de ubicación
    const locationButton = figma.createEllipse();
    locationButton.resize(48, 48);
    locationButton.x = 320;
    locationButton.y = 580;
    locationButton.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    locationButton.strokes = [{ type: "SOLID", color: { r: 0.8, g: 0.8, b: 0.8 } }];
    locationButton.strokeWeight = 1;
    frame.appendChild(locationButton);

    // Icono de ubicación
    const locationIcon = figma.createEllipse();
    locationIcon.resize(20, 20);
    locationIcon.x = 332;
    locationIcon.y = 590;
    locationIcon.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
    frame.appendChild(locationIcon);

    // Botón de filtros (arriba del botón de ubicación)
    const filterButton = figma.createEllipse();
    filterButton.resize(48, 48);
    filterButton.x = 320;
    filterButton.y = 520;
    filterButton.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    filterButton.strokes = [{ type: "SOLID", color: { r: 0.8, g: 0.8, b: 0.8 } }];
    filterButton.strokeWeight = 1;
    frame.appendChild(filterButton);

    // Icono de filtros (tres líneas horizontales)
    const filterIcon1 = figma.createRectangle();
    filterIcon1.resize(20, 2);
    filterIcon1.x = 330;
    filterIcon1.y = 530;
    filterIcon1.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
    frame.appendChild(filterIcon1);

    const filterIcon2 = figma.createRectangle();
    filterIcon2.resize(20, 2);
    filterIcon2.x = 330;
    filterIcon2.y = 535;
    filterIcon2.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
    frame.appendChild(filterIcon2);

    const filterIcon3 = figma.createRectangle();
    filterIcon3.resize(20, 2);
    filterIcon3.x = 330;
    filterIcon3.y = 540;
    filterIcon3.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
    frame.appendChild(filterIcon3);

    // Logo de Google (como en la imagen real)
    const googleLogo = figma.createText();
    googleLogo.characters = "Google";
    googleLogo.fontSize = 12;
    googleLogo.fontName = { family: "Inter", style: "Regular" };
    googleLogo.x = 20;
    googleLogo.y = 720;
    googleLogo.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
    frame.appendChild(googleLogo);

    // Menú inferior
    const bottomMenuBar = figma.createRectangle();
    bottomMenuBar.resize(390, 80);
    bottomMenuBar.x = 0;
    bottomMenuBar.y = 764;
    bottomMenuBar.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    bottomMenuBar.strokes = [{ type: "SOLID", color: { r: 0.9, g: 0.9, b: 0.9 } }];
    bottomMenuBar.strokeWeight = 1;
    frame.appendChild(bottomMenuBar);

    // Elementos del menú
    const menuItems = [
        { type: "circle", label: "Explorar", selected: true },
        { type: "star", label: "Guardados", selected: false },
        { type: "diamond", label: "Eventos", selected: false },
        { type: "square", label: "Perfil", selected: false }
    ];

    menuItems.forEach((item, index) => {
        let menuIcon;
        const iconX = index * 97.5 + 37;
        const iconY = 790;
        const iconSize = 20;
        const iconColor = item.selected ? { r: 0.1, g: 0.6, b: 0.8 } : { r: 0.6, g: 0.6, b: 0.6 };

        if (item.type === "circle") {
            menuIcon = figma.createEllipse();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        } else if (item.type === "star") {
            menuIcon = figma.createStar();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        } else if (item.type === "diamond") {
            menuIcon = figma.createPolygon();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        } else if (item.type === "square") {
            menuIcon = figma.createRectangle();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        }

        frame.appendChild(menuIcon);

        const menuLabel = figma.createText();
        menuLabel.characters = item.label;
        menuLabel.fontSize = 12;
        menuLabel.fontName = { family: "Inter", style: "Regular" };
        menuLabel.x = index * 97.5 + 25;
        menuLabel.y = 820;
        menuLabel.fills = [{ type: "SOLID", color: item.selected ? { r: 0.1, g: 0.6, b: 0.8 } : { r: 0.6, g: 0.6, b: 0.6 } }];
        frame.appendChild(menuLabel);
    });

    console.log("✅ Pantalla Home Customer creada");
    return frame;
}

function createSavedScreen() {
    console.log("❤️ Creando pantalla de guardados...");

    const frame = figma.createFrame();
    frame.resize(390, 844);
    frame.x = 1600;
    frame.y = 100;
    frame.name = "Guardados";
    frame.fills = [{ type: "SOLID", color: { r: 0.98, g: 0.98, b: 0.98 } }];
    frame.cornerRadius = 20;
    figma.currentPage.appendChild(frame);

    createScreenLabel("Guardados", 1725, 70);
    createStatusBar(frame, 20, 15);

    // Título de la pantalla
    const title = figma.createText();
    title.characters = "Mis Favoritos";
    title.fontSize = 28;
    title.fontName = { family: "Inter", style: "Bold" };
    title.x = 27.5;
    title.y = 120;
    title.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
    frame.appendChild(title);

    // Contador de favoritos
    const counter = figma.createText();
    counter.characters = "3 restaurantes guardados";
    counter.fontSize = 14;
    counter.fontName = { family: "Inter", style: "Regular" };
    counter.x = 27.5;
    counter.y = 160;
    counter.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
    frame.appendChild(counter);

    // Lista de restaurantes favoritos
    const restaurants = [
        { name: "Burger Palace", rating: "4.8", distance: "0.5km" },
        { name: "The Burger House", rating: "4.6", distance: "1.2km" },
        { name: "Burger Express", rating: "4.9", distance: "0.8km" }
    ];

    restaurants.forEach((restaurant, index) => {
        const yPosition = 200 + (index * 120);

        // Tarjeta del restaurante
        const card = figma.createRectangle();
        card.resize(335, 100);
        card.x = 27.5;
        card.y = yPosition;
        card.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
        card.cornerRadius = 12;
        card.strokes = [{ type: "SOLID", color: { r: 0.9, g: 0.9, b: 0.9 } }];
        card.strokeWeight = 1;
        frame.appendChild(card);

        // Icono del restaurante (círculo con inicial)
        const icon = figma.createEllipse();
        icon.resize(40, 40);
        icon.x = 45;
        icon.y = yPosition + 15;
        icon.fills = [{ type: "SOLID", color: { r: 0.1, g: 0.6, b: 0.8 } }];
        frame.appendChild(icon);

        const iconText = figma.createText();
        iconText.characters = restaurant.name.charAt(0);
        iconText.fontSize = 18;
        iconText.fontName = { family: "Inter", style: "Bold" };
        iconText.x = 58;
        iconText.y = yPosition + 25;
        iconText.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
        frame.appendChild(iconText);

        // Nombre del restaurante
        const name = figma.createText();
        name.characters = restaurant.name;
        name.fontSize = 16;
        name.fontName = { family: "Inter", style: "Bold" };
        name.x = 100;
        name.y = yPosition + 20;
        name.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 } }];
        frame.appendChild(name);

        // Rating
        const rating = figma.createText();
        rating.characters = "Rating: " + restaurant.rating;
        rating.fontSize = 14;
        rating.fontName = { family: "Inter", style: "Regular" };
        rating.x = 100;
        rating.y = yPosition + 45;
        rating.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
        frame.appendChild(rating);

        // Distancia
        const distance = figma.createText();
        distance.characters = restaurant.distance;
        distance.fontSize = 14;
        distance.fontName = { family: "Inter", style: "Regular" };
        distance.x = 100;
        distance.y = yPosition + 65;
        distance.fills = [{ type: "SOLID", color: { r: 0.4, g: 0.4, b: 0.4 } }];
        frame.appendChild(distance);

        // Botón de eliminar favorito
        const removeButton = figma.createEllipse();
        removeButton.resize(24, 24);
        removeButton.x = 320;
        removeButton.y = yPosition + 15;
        removeButton.fills = [{ type: "SOLID", color: { r: 0.95, g: 0.3, b: 0.3 } }];
        frame.appendChild(removeButton);

        const removeIcon = figma.createText();
        removeIcon.characters = "×";
        removeIcon.fontSize = 18;
        removeIcon.fontName = { family: "Inter", style: "Bold" };
        removeIcon.x = 328;
        removeIcon.y = yPosition + 18;
        removeIcon.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
        frame.appendChild(removeIcon);
    });

    // Menú inferior (con Guardados seleccionado)
    const bottomMenuBar = figma.createRectangle();
    bottomMenuBar.resize(390, 80);
    bottomMenuBar.x = 0;
    bottomMenuBar.y = 764;
    bottomMenuBar.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    bottomMenuBar.strokes = [{ type: "SOLID", color: { r: 0.9, g: 0.9, b: 0.9 } }];
    bottomMenuBar.strokeWeight = 1;
    frame.appendChild(bottomMenuBar);

    // Elementos del menú (con Guardados seleccionado)
    const menuItems = [
        { type: "circle", label: "Explorar", selected: false },
        { type: "star", label: "Guardados", selected: true },
        { type: "diamond", label: "Eventos", selected: false },
        { type: "square", label: "Perfil", selected: false }
    ];

    menuItems.forEach((item, index) => {
        let menuIcon;
        const iconX = index * 97.5 + 37;
        const iconY = 790;
        const iconSize = 20;
        const iconColor = item.selected ? { r: 0.1, g: 0.6, b: 0.8 } : { r: 0.6, g: 0.6, b: 0.6 };

        if (item.type === "circle") {
            menuIcon = figma.createEllipse();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        } else if (item.type === "star") {
            menuIcon = figma.createStar();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        } else if (item.type === "diamond") {
            menuIcon = figma.createPolygon();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        } else if (item.type === "square") {
            menuIcon = figma.createRectangle();
            menuIcon.resize(iconSize, iconSize);
            menuIcon.x = iconX;
            menuIcon.y = iconY;
            menuIcon.fills = [{ type: "SOLID", color: iconColor }];
        }

        frame.appendChild(menuIcon);

        const menuLabel = figma.createText();
        menuLabel.characters = item.label;
        menuLabel.fontSize = 12;
        menuLabel.fontName = { family: "Inter", style: "Regular" };
        menuLabel.x = index * 97.5 + 25;
        menuLabel.y = 820;
        menuLabel.fills = [{ type: "SOLID", color: item.selected ? { r: 0.1, g: 0.6, b: 0.8 } : { r: 0.6, g: 0.6, b: 0.6 } }];
        frame.appendChild(menuLabel);
    });

    console.log("✅ Pantalla de guardados creada");
    return frame;
}

// ===== FUNCIÓN PRINCIPAL =====
async function createAllScreens() {
    console.log("🚀 Iniciando creación de pantallas...");

    try {
        await loadFonts();
        clearPage();

        const loginFrame = createLoginScreen();
        const registerFrame = createRegisterScreen();
        const exploreFrame = await createHomeCustomerScreen();
        const savedFrame = createSavedScreen();

        // Crear flechas
        console.log("➡️ Creando flechas entre pantallas...");
        createArrow(535, 535, 615, 535); // Login → Register
        createArrow(535, 200, 615, 200); // Login → Explorar
        createArrow(1015, 200, 1095, 200); // Explorar → Guardados

        console.log("🎯 Centrando vista...");
        figma.viewport.scrollAndZoomIntoView([loginFrame, registerFrame, exploreFrame, savedFrame]);

        console.log("✅ Script completado exitosamente");
        figma.notify("¡Pantallas creadas exitosamente!");

    } catch (error) {
        console.error("❌ Error:", error);
        figma.notify("Error: " + error.message);
    }
}

// Ejecutar el script
createAllScreens(); 