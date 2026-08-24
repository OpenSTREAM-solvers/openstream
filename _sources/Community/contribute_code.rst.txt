Contribute to the code
======================

We welcome contributions from the community to improve the **OpenSTREAM** solvers, documentation, and examples. Please follow these guidelines to ensure a smooth process.

How to Contribute
-----------------

1. **Fork the Repository**

.. 

   - The OpenSTREAM repository is available at `OpenSTREAM-solvers/openstream <https://github.com/OpenSTREAM-solvers/openstream>`_
   - Click the **Fork** button on GitHub to create your copy.

.. 

2. **Clone Your Fork**

.. 

.. code-block:: bash

   git clone https://github.com/<your-username>/openstream.git
   cd openstream

3. **Create a Feature Branch**

.. code-block:: bash

   git checkout -b feature/my-new-feature

4. **Make Your Changes**

.. 

   - Follow the coding standards outlined below.
   - Add or update tests for new functionality.

.. 

5. **Commit and Push**

.. code-block:: bash

   git commit -m "Add feature: description"
   git push origin feature/my-new-feature

6. **Open a Pull Request**

.. 

   - Go to the original repository and submit a PR.
   - Include a clear description of your changes.

Coding Standards
----------------

- **Python**: Follow PEP8 guidelines.
- **MATLAB**: Use clear variable names, comments, and avoid hard-coded paths.
- Document all functions with docstrings or comments.
- Prefer automated tests over manual verification whenever practical.
- Keep commits atomic and descriptive.

Testing
-------

OpenSTREAM includes automated unit, integration, and environment tests.

Before submitting a pull request, run the complete test suite from MATLAB:

.. code-block:: matlab

   results = runOpenSTREAMTests;

The test runner executes:

- Unit tests in ``tests/unit``
- Integration tests in ``tests/integration``
- Environment validation tests in ``tests/environment``

Contributors should:

- Add unit tests for new classes and functions whenever possible.
- Add integration tests when solver behaviour or numerical results are affected.
- Update reference solutions only when changes are intentional and justified.
- Ensure all tests pass before submitting a pull request.

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
