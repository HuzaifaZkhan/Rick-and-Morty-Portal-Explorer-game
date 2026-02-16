/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'toxic-green': '#00FF41',
        'deep-violet': '#1A0033',
        'lime-green': '#00CC00',
        'near-black': '#0A001A',
        'light-cyan': '#E0FFFF',
        'pale-green': '#99FF99',
        'portal-glow': '#00FF41',
      },
      fontFamily: {
        'primary': ['Audiowide', 'cursive'],
        'secondary': ['Space Mono', 'monospace'],
      },
      keyframes: {
        pulsate: {
          '0%, 100%': { 
            boxShadow: '0 0 10px #00FF41, 0 0 20px #00FF41, 0 0 30px #00FF41',
            borderColor: '#00FF41',
          },
          '50%': { 
            boxShadow: '0 0 20px #00FF41, 0 0 30px #00FF41, 0 0 40px #00FF41, 0 0 50px #00FF41',
            borderColor: '#00CC00',
          },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-20px)' },
        },
        particle: {
          '0%': { transform: 'translateY(0) translateX(0)', opacity: '0' },
          '10%': { opacity: '1' },
          '90%': { opacity: '1' },
          '100%': { transform: 'translateY(-100vh) translateX(var(--tx))', opacity: '0' },
        },
      },
      animation: {
        pulsate: 'pulsate 2s ease-in-out infinite',
        float: 'float 3s ease-in-out infinite',
        particle: 'particle var(--duration) linear infinite',
      },
    },
  },
  plugins: [],
}

