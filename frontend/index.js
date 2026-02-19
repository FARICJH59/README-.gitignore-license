// AxiomCore Frontend Entry Point
// This is the main entry point for the AxiomCore MVP frontend application

import React from 'react';
import ReactDOM from 'react-dom/client';

const App = () => {
  return (
    <div className="app">
      <header>
        <h1>AxiomCore MVP</h1>
        <p>Backend, Frontend, AI Orchestration</p>
      </header>
      <main>
        <p>Welcome to AxiomCore - Energy optimization and forecasting platform</p>
      </main>
    </div>
  );
};

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
