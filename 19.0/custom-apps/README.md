# Custom Apps / Addons

Place your custom Odoo modules/addons in this folder. Each custom module should have its own subdirectory with a proper `__manifest__.py` file.

## Example structure:

```
custom-apps/
├── my_custom_module/
│   ├── __init__.py
│   ├── __manifest__.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── my_model.py
│   ├── views/
│   │   └── my_view.xml
│   └── static/
│       └── description/
│           └── icon.png
└── another_module/
    ├── __init__.py
    ├── __manifest__.py
    └── ...
```

## To activate your custom modules:

1. Start Odoo with: `docker compose up`
2. Access Odoo at `http://localhost:8069`
3. Go to **Apps** menu
4. Search for your module and click **Install**

## Tips:

- Changes to Python files may require restarting the container: `docker compose restart odoo`
- Changes to XML/data files can be reloaded without restart in debug mode
- Check logs with: `docker compose logs -f odoo`
