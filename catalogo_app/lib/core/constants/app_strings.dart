abstract final class AppStrings {
  static const String appTitle = "Catálogo Virtual";

  // Auth
  static const String loginTitle = "Catálogo Virtual";
  static const String welcomeBack = "¡Bienvenido de nuevo!";
  static const String loginSubtitle =
      "Inicia sesión para gestionar tu catálogo.";
  static const String emailLabel = "Correo";
  static const String passwordLabel = "Contraseña";
  static const String signIn = "Ingresar";
  static const String invalidCredentials = "Credenciales inválidas";
  static const String rememberUser = "Recordar usuario";

  // Common actions
  static const String create = "Crear";
  static const String save = "Guardar";
  static const String edit = "Editar";
  static const String delete = "Eliminar";
  static const String cancel = "Cancelar";
  static const String share = "Compartir";
  static const String copyLink = "Copiar enlace";
  static const String linkCopied = "Enlace copiado";
  static const String requiredField = "Requerido";
  static const String invalidValue = "Inválido";
  static const String emailInvalid = "Correo electrónico inválido";
  static const String passwordMinLength = "Mínimo 8 caracteres";
  static const String fieldTooLong = "Máximo {n} caracteres";
  static const String pricePositive = "Debe ser mayor que 0";
  static const String discountRange = "Debe estar entre 0 y 100";
  static const String savedSuccessfully = "Guardado correctamente";
  static const String deletedSuccessfully = "Eliminado correctamente";
  static const String logout = "Cerrar sesión";
  static const String nameLabel = "Nombre";
  static const String retry = "Reintentar";

  // Errors
  static const String sessionExpired =
      "Sesión expirada. Inicia sesión nuevamente.";
  static const String forbidden =
      "No tienes permisos para realizar esta acción.";
  static const String notFound = "El recurso solicitado no existe.";
  static const String serverError =
      "Error interno del servidor. Intenta más tarde.";
  static const String connectionError =
      "Error de conexión. Verifica tu internet.";
  static const String unexpectedError = "Ocurrió un error inesperado.";
  static const String somethingWentWrong = "Algo salió mal";

  // Products
  static const String productsTitle = "Productos";
  static const String searchByKeyword = "Buscar por nombre, código o categoría";
  static const String noSearchResults = "Sin resultados para la búsqueda";
  static const String newProduct = "Nuevo producto";
  static const String editProduct = "Editar producto";
  static const String noProducts = "Sin productos";
  static const String noProductsHint =
      "Agrega tu primer producto para mostrarlo en el catálogo.";
  static const String priceLabel = "Precio";
  static const String discountLabel = "Descuento (%)";
  static const String codeLabel = "Código";
  static const String descriptionLabel = "Descripción";
  static const String availableLabel = "Disponible";
  static const String featuredLabel = "Destacado";
  static const String photosTitle = "Fotos";
  static const String uploadPhoto = "Subir foto";
  static const String imageUploadError = "Error al subir imagen";
  static const String deleteProductTitle = "Eliminar producto";
  static const String deleteProductMessage =
      "¿Seguro que deseas eliminar este producto?";

  // Companies
  static const String companiesTitle = "Mis empresas";
  static const String newCompany = "Nueva empresa";
  static const String editCompany = "Editar empresa";
  static const String noCompanies = "No tienes empresas creadas";
  static const String noCompaniesHint =
      "Crea tu primera empresa para comenzar a armar tu catálogo.";
  static const String companyLabel = "Empresa";
  static const String whatsappLabel = "WhatsApp (506 + 8 dígitos)";
  static const String companyLogoLabel = "Logo (opcional)";
  static const String whatsappHint = "50688888888";
  static const String whatsappInvalid = "Debe ser 506 + 8 dígitos";
  static const String yourCatalog = "Tu catálogo";
  static const String shareCatalogHint =
      "Comparte este enlace con tus clientes:";
  static const String deleteCompanyTitle = "Eliminar empresa";
  static const String deleteCompanyMessage =
      "¿Seguro que deseas eliminar esta empresa?";

  // Categories
  static const String categoriesTitle = "Categorías";
  static const String newCategory = "Nueva categoría";
  static const String editCategory = "Editar categoría";
  static const String noCategories = "Sin categorías para esta empresa";
  static const String noCategoriesHint =
      "Crea categorías para organizar tus productos.";
  static const String categoryLabel = "Categoría";
  static const String deleteCategoryTitle = "Eliminar categoría";
  static const String deleteCategoryMessage =
      "¿Seguro que deseas eliminar esta categoría?";

  // Public catalog
  static const String catalogTitle = "Catálogo";
  static const String productDetail = "Detalle";
  static const String searchProducts = "Buscar productos";
  static const String all = "Todos";
  static const String downloadPdf = "Descargar PDF";
  static const String outOfStock = "Agotado";
  static const String consultWhatsApp = "Consultar por WhatsApp";
  static const String shareProduct = "Compartir producto";
  static const String whatsappLinkCopied = "Enlace copiado";
  static const String shareCatalogText = "Mira el catálogo de {name}: {url}";
  static const String shareProductText = "Mira {name}: {url}";

  // Selectors
  static const String selectCompany = "Selecciona una empresa";
  static const String manageMyCompanies = "Gestionar mis empresas";
  static const String viewPublicCatalog = "Ver catálogo público";
  static const String shareCatalog = "Compartir catálogo";
  static const String configureCompany = "Configurar empresa";
  static const String whatsAppPrefix = "WhatsApp: ";

  // Admin
  static const String adminCompanies = "Empresas";
  static const String adminUsers = "Usuarios";
  static const String adminLicenses = "Licencias";
  static const String createUser = "Crear usuario";
  static const String editUser = "Editar usuario";
  static const String createLicense = "Crear licencia";
  static const String editLicense = "Editar licencia";
  static const String roleLabel = "Rol";
  static const String firstNameLabel = "Nombre";
  static const String lastNameLabel = "Apellido";
  static const String tenantIdLabel = "Tenant ID";
  static const String maxCompaniesLabel = "Máx. empresas";
  static const String maxProductsLabel = "Máx. productos";
  static const String licenseLabel = "Licencia";
  static const String noLicense = "Sin licencia";
  static const String birthDateLabel = "Fecha de nacimiento";
  static const String expiresAtLabel = "Expira";
  static const String noExpiration = "Sin expiración";
  static const String assignLicense = "Asignar licencia";
  static const String activeLabel = "Activo";
  static const String inactiveLabel = "Inactivo";
  static const String activate = "Activar";
  static const String deactivate = "Desactivar";
  static const String isEnabledLabel = "Habilitado";
  static const String deleteUserTitle = "Eliminar usuario";
  static const String deleteUserMessage =
      "¿Seguro que deseas eliminar este usuario?";
  static const String deleteLicenseTitle = "Eliminar licencia";
  static const String deleteLicenseMessage =
      "¿Seguro que deseas eliminar esta licencia?";

  // Home
  static const String greeting = "Hola, {name}";
  static const String sectionCompanies = "Mis empresas";
  static const String adminSection = "Administración";
}