const fs = require('fs');
const path = require('path');
const { minify } = require('terser');
const CleanCSS = require('clean-css');

const pub = path.join(__dirname, '..', 'public');

async function minifyJS(file) {
  const srcPath = path.join(pub, file);
  const code = fs.readFileSync(srcPath, 'utf8');

  // Специальные настройки для admin-script.js
  const isAdminScript = file === 'admin-script.js';

  const options = isAdminScript ? {
    // Безопасные настройки для admin-script.js
    compress: {
      drop_console: false, // Сохраняем console.log
      drop_debugger: true,
      pure_funcs: ['console.log', 'console.info', 'console.debug'],
      // Отключаем агрессивные оптимизации
      sequences: false,
      dead_code: false,
      conditionals: false,
      booleans: false,
      loops: false,
      unused: false,
      hoist_funs: false,
      keep_fargs: true,
      hoist_vars: false,
      if_return: false,
      join_vars: false,
      side_effects: false
    },
    mangle: {
      // Защищаем все важные функции
      reserved: [
        'toggleDishStatus', 'editDish', 'deleteDish', 'editCategory', 'deleteCategory',
        'removeSubcategoryRow', 'showDishModal', 'closeDishModal', 'showCategoryModal',
        'closeCategoryModal', 'loadDishes', 'loadCategories', 'renderDishes',
        'renderCategories', 'apiRequest', 'showSuccess', 'showError', 'showNotification',
        'login', 'logout', 'isAuthenticated', 'loadData', 'clearDishForm', 'clearCategoryForm',
        'updateSubcategorySelect', 'addSubcategoryRow', 'removeSubcategoryRow',
        'handleMainImageUpload', 'handleGalleryImagesUpload', 'updateMainImagePreview',
        'updateGalleryImagesPreview', 'removeMainImage', 'removeGalleryImage',
        'uploadImage', 'uploadImages', 'saveDish', 'updateDish', 'saveCategory', 'updateCategory',
        'loadDishForEdit', 'loadCategoryForEdit', 'showSection', 'debounce'
      ]
    },
    format: {
      comments: false
    }
  } : {
    // Обычные настройки для других файлов
    compress: {
      drop_console: false,
      drop_debugger: true,
      pure_funcs: ['console.log', 'console.info', 'console.debug']
    },
    mangle: true,
    format: {
      comments: false
    }
  };

  const result = await minify(code, options);

  if (result.error) {
    console.error(`Ошибка минификации ${file}:`, result.error);
    return;
  }

  fs.writeFileSync(path.join(pub, file.replace('.js', '.min.js')), result.code, 'utf8');
}

function minifyCSS(file) {
  const srcPath = path.join(pub, file);
  const code = fs.readFileSync(srcPath, 'utf8');
  const result = new CleanCSS({ level: 2 }).minify(code);
  fs.writeFileSync(path.join(pub, file.replace('.css', '.min.css')), result.styles, 'utf8');
}

(async function run() {
  await minifyJS('script.js');
  await minifyJS('api.js');
  await minifyJS('admin-script.js'); // Минифицируем с безопасными настройками
  minifyCSS('styles.css');
  if (fs.existsSync(path.join(pub, 'admin-styles.css'))) {
    minifyCSS('admin-styles.css');
  }
  console.log('Minification completed (admin-script.js с безопасными настройками).');
})();


