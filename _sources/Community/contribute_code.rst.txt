Contribute to the code
======================

We welcome contributions from the community to improve the **OpenSTREAM** solvers, documentation, and examples. Please follow these guidelines to ensure a smooth process.

How to Contribute
-----------------

1. **Fork the Repository**

.. raw:: html

   <br>

   - Click the **Fork** button on GitHub to create your copy.

.. raw:: html

   <br>

2. **Clone Your Fork**

.. raw:: html

   <br>

.. code-block:: bash

   git clone https://github.com/<your-username>/openstream.git
   cd openstream

3. **Create a Feature Branch**

.. code-block:: bash

   git checkout -b feature/my-new-feature

4. **Make Your Changes**

.. raw:: html

   <br>

   - Follow the coding standards outlined below.
   - Add tests for new functionality.

.. raw:: html

   <br>

5. **Commit and Push**

.. code-block:: bash

   git commit -m "Add feature: description"
   git push origin feature/my-new-feature

6. **Open a Pull Request**

.. raw:: html

   <br>

   - Go to the original repository and submit a PR.
   - Include a clear description of your changes.

Coding Standards
----------------

- **Python**: Follow PEP8 guidelines.
- **MATLAB**: Use clear variable names, comments, and avoid hard-coded paths.
- Document all functions with docstrings or comments.
- Keep commits atomic and descriptive.

Testing
-------

- Run existing tests (*coming soon*) before submitting changes.
- Add new tests for any new functionality.
- Use ``pytest`` for Python and built-in MATLAB testing frameworks where applicable.

Reporting Issues
----------------

- Use the issue `tracker <https://github.com/OpenSTREAM-solvers/openstream/issues>`_ on GitHub.
- Provide:

  - Steps to reproduce
  - Expected vs actual behavior
  - Screenshots or logs if relevant

Code of Conduct
---------------

Please be respectful and constructive in all interactions.

Communication
-------------

- Join discussions in `GitHub Discussions <https://github.com/OpenSTREAM-solvers/discussions>`_. 
- For major changes, open an issue first to discuss your proposal.
