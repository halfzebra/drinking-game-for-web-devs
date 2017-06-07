import './main.css';
import nounList from './noun-list.json';
import { Main } from './Main.elm';

Main.embed(document.getElementById('root'), nounList);